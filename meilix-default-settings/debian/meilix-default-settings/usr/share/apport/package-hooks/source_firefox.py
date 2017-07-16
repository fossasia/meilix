'''firefox apport hook

/usr/share/apport/package-hooks/firefox.py

Copyright (c) 2007: Hilario J. Montoliu <hmontoliu@gmail.com>
          (c) 2011: Chris Coulson <chris.coulson@canonical.com>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.  See http://www.gnu.org/copyleft/gpl.html for
the full text of the license.
'''

import os
import os.path
import sys
import fcntl
import subprocess
import struct
from subprocess import Popen
try:
    from configparser import ConfigParser
except ImportError:
    from ConfigParser import ConfigParser
import sqlite3
import tempfile
import re
import apport.packaging
from apport.hookutils import *
from glob import glob
import zipfile
import stat
import functools
if sys.version_info[0] < 3:
    import codecs

DISTRO_ADDONS = [
    'firefox',
    'xul-ext-ubufox'
]

class PrefParseError(Exception):
    def __init__(self, msg, filename, linenum):
        super(PrefParseError, self).__init__(msg)
        self.msg = msg
        self.filename = filename
        self.linenum = linenum

    def __str__(self):
        return self.msg + ' @ ' + self.filename + ':' + str(self.linenum)

class PluginRegParseError(Exception):
    def __init__(self, msg, linenum):
        super(PluginRegParseError, self).__init__(msg)
        self.msg = msg
        self.linenum = linenum

    def __str__(self):
        return self.msg + ' @ line ' + str(self.linenum)


class ExtensionTypeNotRecognised(Exception):
    def __init__(self, ext_type, ext_id):
        super(ExtensionTypeNotRecognised, self).__init__(ext_type, ext_id)
        self.ext_type = ext_type
        self.ext_id = ext_id

    def __str__(self):
        return "Extension type not recognised: %s (ID: %s)" % (self.ext_type, self.ext_id)


class VersionCompareFailed(Exception):
    def __init__(self, a, b, e):
        if a == None:
            a = ''
        if b == None:
            b = ''
        super(VersionCompareFailed, self).__init__(a, b, e)
        self.a = a
        self.b = b
        self.e = e

    def __str__(self):
        return "Failed to compare versions A = %s, B = %s (%s)" % (self.a, self.b, str(self.e))


def _open(filename, mode):
    if sys.version_info[0] < 3:
        return codecs.open(filename, mode, 'utf-8')
    return open(filename, mode)

def mkstemp_copy(path):
    '''Make a copy of a file to a temporary file, and return the path'''
    (outfd, outpath) = tempfile.mkstemp()
    outfile = os.fdopen(outfd, 'wb')
    infile = open(path, 'rb')

    total = 0
    while True:
        data = infile.read(4096)
        total += len(data)
        outfile.write(data)
        infile.seek(total)
        outfile.seek(total)
        if len(data) < 4096: break

    return outpath


def anonymize_path(path, profiledir = None):
    if profiledir != None and path == os.path.join(profiledir, 'prefs.js'):
        return 'prefs.js'
    elif profiledir != None and path == os.path.join(profiledir, 'user.js'):
        return 'user.js'
    elif profiledir != None and path.startswith(profiledir):
        return os.path.join('[Profile]', os.path.relpath(path, profiledir))
    elif path.startswith(os.environ['HOME']):
        return os.path.join('[HomeDir]', os.path.relpath(path, os.environ['HOME']))
    else:
        return path


class CompatINIParser(ConfigParser):
    def __init__(self, path):
        ConfigParser.__init__(self)
        self.read(os.path.join(path, "compatibility.ini"))

    @property
    def last_version(self):
        if not self.has_section("Compatibility") or not self.has_option("Compatibility", "LastVersion"):
            return None
        return re.sub(r'([^_]*)(.*)', r'\1', self.get("Compatibility", "LastVersion"))

    @property
    def last_buildid(self):
        if not self.has_section("Compatibility") or not self.has_option("Compatibility", "LastVersion"):
            return None
        return re.sub(r'([^_]*)_([^/]*)/(.*)', r'\2', self.get("Compatibility", "LastVersion"))


class AppINIParser(ConfigParser):
    def __init__(self, path):
        ConfigParser.__init__(self)
        self.read(os.path.join(path, "application.ini"))

    @property
    def buildid(self):
        if not self.has_section('App') or not self.has_option('App', 'BuildID'):
            return None
        return self.get('App', 'BuildID')

    @property
    def appid(self):
        if not self.has_section('App') or not self.has_option('App', 'ID'):
            return None
        return self.get('App', 'ID')


class ExtensionINIParser(ConfigParser):
    def __init__(self, path):
        ConfigParser.__init__(self)
        self.read(os.path.join(path, "extensions.ini"))

        self._extensions = []

        if self.has_section('ExtensionDirs'):
            items = self.items('ExtensionDirs')
            for item in items:
                self._extensions.append(item[1])

    def __getitem__(self, key):
        if key > len(self) - 1:
            raise IndexError
        return self._extensions[key]

    def __iter__(self):

        class ExtensionINIParserIter:
            def __init__(self, parser):
                self.parser = parser
                self.index = 0

            def __next__(self):
                if self.index == len(self.parser):
                    raise StopIteration
                res = self.parser[self.index]
                self.index += 1
                return res

            def next(self):
                return self.__next__()

        return ExtensionINIParserIter(self)

    def __len__(self):
        return len(self._extensions)            

def compare_versions(a, b):
    '''Compare 2 version numbers, returns -1 for a<b, 0 for a=b and 1 for a>b
       This is basically just a python reimplementation of nsVersionComparator'''
    class VersionPart:
        def __init__(self):
            self.numA = 0
            self.strB = None
            self.numC = 0
            self.extraD = None

    def parse_version(part):
        res = VersionPart()
        if part == None or part == '':
            return (part, res)
        spl = part.split('.')

        if part == '*' and len(part) == 1:
            try:
                res.numA = sys.maxint
            except:
                res.numA = sys.maxsize # python3
            res.strB = ""
        else:
            res.numA = int(re.sub(r'([0-9]*)(.*)', r'\1', spl[0]))
            res.strB = re.sub(r'([0-9]*)(.*)', r'\2', spl[0])

        if res.strB == '':
            res.strB = None

        if res.strB != None:
            if res.strB[0] == '+':
                res.numA += 1
                res.strB = "pre"
            else:
                tmp = res.strB
                res.strB = re.sub(r'([^0-9+-]*)([0-9]*)(.*)', r'\1', tmp)
                strC = re.sub(r'([^0-9+-]*)([0-9]*)(.*)', r'\2', tmp)
                if strC != '':
                    res.numC = int(strC)
                res.extraD = re.sub(r'([^0-9+-]*)([0-9]*)(.*)', r'\3', tmp)
                if res.extraD == '':
                    res.extraD = None

        return (re.sub(r'([^\.]*)\.*(.*)', r'\2', part), res)

    def strcmp(stra, strb):
        if stra == None and strb == None:
            return 0
        elif stra == None and strb != None:
            return 1
        elif stra != None and strb == None:
            return -1
        if stra < strb:
            return -1
        elif stra > strb:
            return 1
        else:
            return 0

    def do_compare(apart, bpart):
        if apart.numA < bpart.numA:
            return -1
        elif apart.numA > bpart.numA:
            return 1

        res = strcmp(apart.strB, bpart.strB)
        if res != 0:
            return res

        if apart.numC < bpart.numC:
            return -1
        elif apart.numC > bpart.numC:
            return 1

        return strcmp(apart.extraD, bpart.extraD)

    try:
        saved_a = a
        saved_b = b
        while a or b:
            (a, va) = parse_version(a)
            (b, vb) = parse_version(b)

            res = do_compare(va, vb)
            if res != 0:
                break
    except Exception as e:
        raise VersionCompareFailed(saved_a, saved_b, e)

    return res


class Plugin(object):
    def __init__(self):
        self.lib = None
        self.path = None
        self.desc = None
        self._package = None
        self._checked_package = False

    def dump(self):
        if self.path.startswith(os.path.join(os.environ['HOME'], '.mozilla', 'firefox')):
            location = "[Profile]"
        else:
            location = os.path.dirname(self.path)

        pkgname = ' (%s)' % self.package if self.package != None else ''
        return ("%s - %s%s" % (self.desc, os.path.join(location, self.lib), pkgname))

    @property
    def package(self):
        if self._checked_package == False:
            self._package = apport.packaging.get_file_package(self.path)
            self._checked_package = True
        return self._package

class PluginRegistry:

    STATE_PENDING = 0
    STATE_START = 1
    STATE_PROCESSING_1 = 2
    STATE_PROCESSING_2 = 3
    STATE_PROCESSING_3 = 4
    STATE_FINISHED = 5

    def __init__(self, path):
        self.plugins = []
        self._state = PluginRegistry.STATE_PENDING
        self._current_plugin = None
        self._profile_path = path
        self.error = None

        fd = None
        try:
            fd = _open(os.path.join(path, 'pluginreg.dat'), 'r')
            try:
                skip = 0
                linenum = 1
                for line in fd.readlines():
                    if skip == 0:
                        skip = self._parseline(line, linenum)
                        if skip == -1:
                            break
                    else:
                        skip -= 1
                    linenum += 1
                if skip > 0:
                    raise PluginRegParseError("Unexpected EOF", linenum)
            except Exception as e:
                self.error = str(e)
        except:
            pass
        finally:
            if fd != None:
                fd.close()

    def _parseline(self, line, linenum):
        line = line.strip()
        if line != '' and line[0] == '[' and self._state != PluginRegistry.STATE_START and self._state != PluginRegistry.STATE_PENDING:
            raise PluginRegParseError('Unexpected section header', linenum)

        if self._state == PluginRegistry.STATE_PENDING:
            if line == '[PLUGINS]':
                self._state += 1
            return 0
        elif self._state == PluginRegistry.STATE_START:
            if line == '':
                return 0
            if line[0] == '[':
                self._state = PluginRegistry.STATE_FINISHED
                return -1
            self._current_plugin = Plugin()
            self._current_plugin.lib = line.split(':')[0]
            self._state += 1
            return 0
        elif self._state == PluginRegistry.STATE_PROCESSING_1:
            path = line.split(':')[0]
            if path[0] != '/':
                raise PluginRegParseError("Invalid path", linenum)
            self._current_plugin.path = anonymize_path(path, self._profile_path)
            self._state += 1
            return 3
        elif self._state == PluginRegistry.STATE_PROCESSING_2:
            self._current_plugin.desc = line.split(':')[0]
            self._state += 1
            return 0
        elif self._state == PluginRegistry.STATE_PROCESSING_3:
            self.plugins.append(self._current_plugin)
            self._state = PluginRegistry.STATE_START
            return int(line.strip())
        else:
            return -1

    def __getitem__(self, key):
        if key > len(self) - 1:
            raise IndexError
        return self.plugins[key]

    def __iter__(self):

        class PluginRegistryIter:
            def __init__(self, registry):
                self.registry = registry
                self.index = 0

            def __next__(self):
                if self.index == len(self.registry):
                    raise StopIteration
                ret = self.registry[self.index]
                self.index += 1
                return ret

            def next(self):
                return self.__next__()

        return PluginRegistryIter(self)

    def __len__(self):
        return len(self.plugins)


class Prefs:
    '''Class which represents a pref file. Handles all of the parsing, and can be accessed
       like a normal python dictionary'''
    PREF_WHITELIST = [
        r'accessibility\.*',
        r'browser\.fixup\.*',
        r'browser\.history_expire_*',
        r'browser\.link\.open_newwindow',
        r'browser\.mousewheel\.*',
        r'browser\.places\.*',
        r'browser\.startup\.homepage',
        r'browser\.tabs\.*',
        r'browser\.zoom\.*',
        r'dom\.*',
        r'extensions\.autoDisableScopes',
        r'extensions\.checkCompatibility\.*',
        r'extensions\.enabledScopes',
        r'extensions\.lastAppVersion',
        r'extensions\.minCompatibleAppVersion',
        r'extensions\.minCompatiblePlatformVersion',
        r'extensions\.strictCompatibility',
        r'font\.*',
        r'general\.skins\.*',
        r'general\.useragent\.*',
        r'gfx\.*',
        r'html5\.*',
        r'mozilla\.widget\.render\-mode',
        r'layers\.*',
        r'javascript\.*',
        r'keyword\.*',
        r'layout\.css\.dpi',
        r'network\.*',
        r'places\.*',
        r'plugin\.*',
        r'plugins\.*',
        r'print\.*',
        r'privacy\.*',
        r'security\.*',
        r'webgl\.*'
    ]

    PREF_BLACKLIST = [
        r'^network.*proxy\.*',
        r'.*print_to_filename$',
        r'print\.tmp\.',
        r'print\.printer_*',
        r'printer_*'
    ]

    STATE_READY = 0
    STATE_COMMENT_MAYBE_START = 1
    STATE_COMMENT_BLOCK = 2
    STATE_COMMENT_BLOCK_MAYBE_END = 3
    STATE_PARSE_UNTIL_OPEN_PAREN = 4
    STATE_PARSE_UNTIL_NAME = 5
    STATE_PARSE_UNTIL_COMMA = 6
    STATE_PARSE_UNTIL_VALUE = 7
    STATE_PARSE_UNTIL_CLOSE_PAREN = 8
    STATE_PARSE_UNTIL_SEMICOLON = 9
    STATE_PARSE_STRING = 10
    STATE_PARSE_ESC_SEQ = 11
    STATE_PARSE_INT = 12
    STATE_SKIP = 13
    STATE_PARSE_UNTIL_EOL = 14

    def __init__(self, profile_path, extra_paths=None, whitelist=None, blacklist=None):
        self.whitelist = whitelist if whitelist != None else Prefs.PREF_WHITELIST
        self.blacklist = blacklist if blacklist != None else Prefs.PREF_BLACKLIST
        self.prefs = {}
        self.pref_sources = []
        self.errors = {}

        self._profile_path = profile_path

        # Read all preferences. Note that we hide preferences that are considered
        # default (ie, all of those set by the Firefox package or bundled addons,
        # unless any of the pref files have been modified by the user).
        # The load order is *very important*
        if profile_path != None:
            locations = [
                "/usr/lib/firefox/omni.ja:greprefs.js",
                "/usr/lib/firefox/omni.ja:defaults/pref/*.js",
                "/usr/lib/firefox/defaults/pref/*.js",
                "/usr/lib/firefox/defaults/pref/unix.js",
                "/usr/lib/firefox/omni.ja:defaults/preferences/*.js"
                "/usr/lib/firefox/defaults/preferences/*.js"
            ]

            append_dirs = [ 'defaults/preferences/*.js' ]
            if os.path.isdir('/usr/lib/firefox/distribution/bundles'):
                bundles = os.listdir('/usr/lib/firefox/distribution/bundles')
                bundles.sort(reverse=True)
                for d in append_dirs:
                    for bundle in bundles:
                        path = os.path.join('/usr/lib/firefox/distribution/bundles', bundle)
                        if path.endswith('.xpi'):
                            locations.append(path + ':' + d)
                        elif os.path.isdir(path):
                            locations.append(os.path.join(path, d))

            locations.append(os.path.join(profile_path, "prefs.js"))
            locations.append(os.path.join(profile_path, "user.js"))

            extensions = ExtensionINIParser(profile_path)
            for extension in extensions:
                if extension.endswith('.xpi'):
                    locations.append(extension + ':defaults/preferences/*.(J|j)(S|s)')
                elif os.path.isdir(extension):
                    locations.append(os.path.join(extension, 'defaults/preferences/*.js'))

            locations.append(os.path.join(profile_path, 'preferences/*.js'))
        else: locations = []

        if extra_paths != None:
            for extra in extra_paths:
                locations.append(extra)

        for location in locations:
            m = re.match(r'^([^:]*):?(.*)', location)
            if m.group(2) == '':
                files = glob(location)
                files.sort(reverse=True)
                for f in files:
                    self._parse_file(f)
            else:
                self._parse_jar(m.group(1), m.group(2))

    def _should_ignore_file(self, filename):
        realpath = os.path.realpath(filename)
        package = apport.packaging.get_file_package(realpath)
        if package and apport.packaging.is_distro_package(package) and \
           package in DISTRO_ADDONS and \
           realpath[1:] not in apport.packaging.get_modified_files(package):
            return True

        return False

    def _parse_file(self, filename):
        f = None
        self._state = Prefs.STATE_READY
        try:
            f = _open(filename, 'r')
            try:
                linenum = 1
                state = None
                for line in f.readlines():
                    state = self._parseline(line, filename, linenum, state)
                    linenum += 1
            except Exception as e:
                self.errors[filename] = str(e)
        except:
            pass
        finally:
            if f != None:
                f.close()
            if filename not in self.errors \
               and not self._should_ignore_file(filename):
                self.pref_sources.append(filename)

    def _parse_jar(self, jar, match):
        jarfile = None
        try:
            jarfile = zipfile.ZipFile(jar)
            entries = jarfile.namelist()
            entries.sort(reverse=True)
            for entry in entries:
                if re.match(r'^' + match + '$', entry):
                    source = '%s:%s' % (jar, entry)
                    try:
                        f = jarfile.open(entry, 'r')
                        linenum = 1
                        state = None
                        for line in f.readlines():
                            state = self._parseline(line.decode('utf-8'),
                                                    source, linenum, state)
                            linenum += 1
                    except Exception as e:
                        self.errors[source] = str(e)
                    finally:
                        if source not in self.errors \
                           and not self._should_ignore_file(jar):
                            self.pref_sources.append(source)
        except:
            pass
        finally:
            if jarfile != None:
                jarfile.close()

    def _maybe_add_pref(self, key, value, source, default, locked):

        class Pref(object):
            def __init__(self, profile_path):
                self._default = None
                self._value = None
                self._default_source = None
                self._value_source = None
                self.locked = False
                self._profile_path = profile_path

            @property
            def value(self):
                if self._value != None:
                    return self._value
                return self._default

            @property
            def source(self):
                if self._value != None: 
                    return self._value_source
                return self._default_source

            @property
            def anon_source(self):
                if self._value != None:
                    return anonymize_path(self._value_source, self._profile_path)
                return anonymize_path(self._default_source, self._profile_path)

            def set_value(self, value, source, default, locked):
                if self.locked == True:
                    return

                if default == True:
                    self._default = value
                    self._default_source = source
                else:
                    self._value = value
                    self._value_source = source
                self.locked = locked

        for match in self.blacklist:
            if re.match(match, key):
                return

        for match in self.whitelist:
            if re.match(match, key):
                if key not in self.prefs:
                    self.prefs[key] = Pref(self._profile_path)

                self.prefs[key].set_value(value, source, default, locked)

    def _parseline(self, line, source, linenum, old_state):
        # XXX: I pity the poor soul who ever needs to change anything inside this function

        class PrefParseState(object):
            def __init__(self):
                self.state = Prefs.STATE_READY

            def _reset(self):
                self.next_state = Prefs.STATE_READY
                self.default = False
                self.locked = False
                self.name = None
                self.value = None
                self.tmp = None
                self.skip = None
                self.quote = None

            def _get_state(self):
                return self._state

            def _set_state(self, state):
                self._state = state
                if state == Prefs.STATE_READY:
                    self._reset()

            state = property(_get_state, _set_state)

        state = old_state

        if state == None:
            state = PrefParseState()

        index = 0
        for c in line:
            if state.state == Prefs.STATE_READY:
                if c == '/':
                    state.state = Prefs.STATE_COMMENT_MAYBE_START
                elif c == '#':
                    state.state = Prefs.STATE_PARSE_UNTIL_EOL
                elif line.startswith('pref', index):
                    state.default == True
                    state.next_state = Prefs.STATE_PARSE_UNTIL_OPEN_PAREN
                    state.state = Prefs.STATE_SKIP
                    state.skip = 3
                elif line.startswith('user_pref', index):
                    state.next_state = Prefs.STATE_PARSE_UNTIL_OPEN_PAREN
                    state.state = Prefs.STATE_SKIP
                    state.skip = 8
                elif line.startswith('lockPref', index):
                    state.default = True
                    state.locked = True
                    state.next_state = Prefs.STATE_PARSE_UNTIL_OPEN_PAREN
                    state.state = Prefs.STATE_SKIP
                    state.skip = 7
                elif not c.isspace():
                    raise PrefParseError("Unexpected character '%s' before pref" % c,
                                         anonymize_path(source, self._profile_path),
                                         linenum)

            elif state.state == Prefs.STATE_SKIP:
                state.skip -= 1
                if state.skip == 0:
                    state.state = state.next_state
                    state.next_state = Prefs.STATE_READY

            elif state.state == Prefs.STATE_COMMENT_MAYBE_START:
                if c == '*':
                    state.state = Prefs.STATE_COMMENT_BLOCK
                elif c == '/':
                    state.state = Prefs.STATE_PARSE_UNTIL_EOL
                else:
                    raise PrefParseError("Unexpected '/'",
                                         anonymize_path(source, self._profile_path),
                                         linenum)

            elif state.state == Prefs.STATE_PARSE_UNTIL_EOL:
                pass

            elif state.state == Prefs.STATE_COMMENT_BLOCK:
                if c == '*':
                    state.state = Prefs.STATE_COMMENT_BLOCK_MAYBE_END

            elif state.state == Prefs.STATE_COMMENT_BLOCK_MAYBE_END:
                if c == '/':
                    state.state = state.next_state
                    state.next_state = Prefs.STATE_READY
                else:
                    state.state = Prefs.STATE_COMMENT_BLOCK

            elif state.state == Prefs.STATE_PARSE_UNTIL_OPEN_PAREN:
                if c == '(':
                    state.state = Prefs.STATE_PARSE_UNTIL_NAME
                elif c == '/':
                    state.next_state = state.state
                    state.state = Prefs.STATE_COMMENT_MAYBE_START
                elif not c.isspace():
                    raise PrefParseError("Unexpected character '%s' before open parenthesis" % c,
                                         anonymize_path(source, self._profile_path),
                                         linenum)

            elif state.state == Prefs.STATE_PARSE_UNTIL_NAME:
                if c == '"' or c == '\'':
                    state.tmp = ''
                    state.quote = c
                    state.state = Prefs.STATE_PARSE_STRING
                    state.next_state = Prefs.STATE_PARSE_UNTIL_COMMA
                elif c == '/':
                    state.next_state = state.state
                    state.state = Prefs.STATE_COMMENT_MAYBE_START
                elif not c.isspace():
                    raise PrefParseError("Unexpected character '%s' before pref name" % c,
                                         anonymize_path(source, self._profile_path),
                                         linenum)

            elif state.state == Prefs.STATE_PARSE_STRING:
                if c == '\\':
                    state.state = Prefs.STATE_PARSE_ESC_SEQ
                elif c == state.quote:
                    state.state = state.next_state
                    state.next_state = Prefs.STATE_READY
                else:
                    state.tmp += c

            elif state.state == Prefs.STATE_PARSE_ESC_SEQ:
                # XXX: We don't handle UTF16 / hex here
                if c == 'n':
                    c = '\n'
                elif c == 'r':
                    c = '\r' 
                state.tmp += c
                state.state = Prefs.STATE_PARSE_STRING

            elif state.state == Prefs.STATE_PARSE_UNTIL_COMMA:
                if state.tmp != None:
                    state.name = state.tmp
                    state.tmp = None
                if c == ',':
                    state.state = Prefs.STATE_PARSE_UNTIL_VALUE
                elif c == '/':
                    state.next_state = state.state
                    state.state = Prefs.STATE_COMMENT_MAYBE_START
                elif not c.isspace():
                    raise PrefParseError("Unexpected character '%s' before comma" % c,
                                         anonymize_path(source, self._profile_path),
                                         linenum)

            elif state.state == Prefs.STATE_PARSE_UNTIL_VALUE:
                if c == '"' or c == '\'':
                    state.tmp = ''
                    state.quote = c
                    state.state = Prefs.STATE_PARSE_STRING
                    state.next_state = Prefs.STATE_PARSE_UNTIL_CLOSE_PAREN
                elif line.startswith('true', index):
                    state.tmp = True
                    state.next_state = Prefs.STATE_PARSE_UNTIL_CLOSE_PAREN
                    state.state = Prefs.STATE_SKIP
                    state.skip = 3
                elif line.startswith('false', index):
                    state.tmp = False
                    state.next_state = Prefs.STATE_PARSE_UNTIL_CLOSE_PAREN
                    state.state = Prefs.STATE_SKIP
                    state.skip = 4
                elif (c >= '0' and c <= '9') or c == '+' or c == '-':
                    state.tmp = c
                    state.state = Prefs.STATE_PARSE_INT
                elif c == '/':
                    state.next_state = state
                    state.state = Prefs.STATE_COMMENT_MAYBE_START
                elif not c.isspace():
                    raise PrefParseError("Unexpected character '%s' before value" % c,
                                         anonymize_path(source, self._profile_path),
                                         linenum)

            elif state.state == Prefs.STATE_PARSE_INT:
                if c >= '0' and c <= '9':
                    state.tmp += c
                elif c == ')':
                    state.value = int(state.tmp)
                    state.tmp = None
                    state.state = Prefs.STATE_PARSE_UNTIL_SEMICOLON
                elif c.isspace():
                    state.tmp = int(state.tmp)
                    state.state = Prefs.STATE_PARSE_UNTIL_CLOSE_PAREN
                elif c == '/':
                    state.tmp = int(state.tmp)
                    state.next_state = Prefs.STATE_PARSE_UNTIL_CLOSE_PAREN
                    state.state = Prefs.STATE_COMMENT_MAYBE_START
                else:
                    raise PrefParseError("Unexpected character '%s' whilst parsing int" % c,
                                         anonymize_path(source, self._profile_path),
                                         linenum)

            elif state.state == Prefs.STATE_PARSE_UNTIL_CLOSE_PAREN:
                if state.tmp != None:
                    state.value = state.tmp
                    state.tmp = None
                if c == ')':
                    state.state = Prefs.STATE_PARSE_UNTIL_SEMICOLON
                elif c == '/':
                    state.next_state = state.state
                    state.state = Prefs.STATE_COMMENT_MAYBE_START
                elif not c.isspace():
                    raise PrefParseError("Unexpected character '%s' before close parenthesis" % c,
                                         anonymize_path(source, self._profile_path),
                                         linenum)

            elif state.state == Prefs.STATE_PARSE_UNTIL_SEMICOLON:
                if c == ';':
                    self._maybe_add_pref(state.name, state.value, source,
                                         state.default, state.locked)
                    state.state = Prefs.STATE_READY
                elif c == '/':
                    state.next_state = state.state
                    state.state = Prefs.STATE_COMMENT_MAYBE_START
                elif not c.isspace():
                    raise PrefParseError("Unexpected character '%s' before semicolon" % c,
                                         anonymize_path(source, self._profile_path),
                                         linenum)

            index += 1

        if state.state == Prefs.STATE_PARSE_UNTIL_EOL:
            state.state = Prefs.STATE_READY

        return state

    def __getitem__(self, key):
        res = self.prefs[key]
        if res.source in self.pref_sources:
            return res
        raise KeyError

    def __iter__(self):

        class PrefsIter:
            def __init__(self, prefs):
                self.index = 0
                self.keys = []
                for k in prefs.prefs.keys():
                    try:
                        test = prefs[k]
                        self.keys.append(k)
                    except:
                        pass
                self.keys.sort()

            def __next__(self):
                if self.index == len(self.keys):
                    raise StopIteration
                res = self.keys[self.index]
                self.index += 1
                return res

            def next(self):
                return self.__next__()

        return PrefsIter(self)

    def __len__(self):
        i = 0
        for k in self:
            i += 1
        return i


class Extension:
    '''Small class representing an extension'''
    def __init__(self, ext_id, location, ver, ext_type, active, desc, min_appver,
                 max_appver, cur_appver, visible, userDisabled, appDisabled,
                 softDisabled, foreign, hasBinary, strictCompat, appStrictCompat):
        self.ext_id = ext_id;
        self.location = location
        self.ver = ver
        self.ext_type = ext_type
        self.active = active
        self.desc = desc
        self.min_appver = min_appver
        self.max_appver = max_appver
        self.cur_appver = cur_appver
        self.visible = visible
        self.userDisabled = userDisabled
        self.appDisabled = appDisabled
        self.softDisabled = softDisabled
        self.foreign = foreign
        self.hasBinary = hasBinary
        self.strictCompat = strictCompat
        self.appStrictCompat = appStrictCompat

    def dump(self):
        active = "Yes" if self.active == True else "No"
        foreign = "Yes" if self.foreign == True else "No"
        visible = "Yes" if self.visible == True else "No"
        hasBinary = "Yes" if self.hasBinary == True else "No"
        strictCompat = "Yes" if self.strictCompat == True else "No"
        if self.active == True:
            disabled_reason = ""
        elif self.softDisabled == True:
            disabled_reason = "(Soft-blocked)"
        elif self.appDisabled == True:
            disabled_reason = "(Application disabled)"
        elif self.userDisabled == True:
            disabled_reason = "(User disabled)"
        else:
            disabled_reason = "(Reason unknown)"

        return ("%s - ID=%s, Version=%s, minVersion=%s, maxVersion=%s, Location=%s, " +
                "Type=%s, Foreign=%s, Visible=%s, BinaryComponents=%s, StrictCompat=%s, " +
                "Active=%s %s") % \
               (self.desc, self.ext_id, self.ver, self.min_appver, self.max_appver,
                self.location, self.ext_type, foreign, visible, hasBinary,
                strictCompat, active, disabled_reason)

    @property
    def active_but_incompatible(self):
        return self.active and (self.cur_appver != None and \
                                (compare_versions(self.cur_appver, self.min_appver) == -1 or \
                                 compare_versions(self.cur_appver, self.max_appver) == 1) and \
                                (self.hasBinary or self.strictCompat or self.appStrictCompat))


class Profile:
    '''Container to represent a profile'''
    def __init__(self, id, name, path, is_default, appini):
        self.extensions = {}
        self.locales = {}
        self.themes = {}
        self.id = id
        self.name = name
        self.path = path
        self.default = is_default
        self.appini = appini

        self.prefs = Prefs(path)
        self.plugins = PluginRegistry(path)

        try:
            self._populate_extensions()
        except:
            self.extensions = None

    def _populate_extensions(self):
        # We copy the db as it's locked whilst Firefox is open. This is still racy
        # though, as it could be modified during the copy, leaving us with a corrupt
        # DB. Can we detect this somehow?
        tmp_db = mkstemp_copy(os.path.join(self.path, "extensions.sqlite"))
        conn = sqlite3.connect(tmp_db)

        def get_extension_from_row(row):
            moz_id = row[0]
            ext_id = row[1]
            location = row[2]
            ext_ver = row[3]
            ext_type = row[4]
            visible = True if row[6] == 1 else False
            active = True if row[7] == 1 else False
            userDisabled = True if row[8] == 1 else False
            appDisabled = True if row[9] == 1 else False
            softDisabled = True if row[10] == 1 else False
            foreign = True if row[11] == 1 else False
            hasBinary = True if row[12] == 1 else False
            strictCompat = True if row[13] == 1 else False

            cur = conn.cursor()
            cur.execute("select name from locale where id=:id", { "id": row[5] })
            desc = cur.fetchone()[0]

            cur = conn.cursor()
            cur.execute("select minVersion, maxVersion from targetApplication where addon_internal_id=:id and (id=:appid or id=:tkid)", \
                        { "id": row[0], "appid": self.appini.appid, "tkid": "toolkit@mozilla.org" })
            (min_ver, max_ver) = cur.fetchone()

            appStrictCompat = 'extensions.strictCompatibility' in self.prefs and \
                              self.prefs['extensions.strictCompatibility'].value == 'true'
            return Extension(ext_id, location, ext_ver, ext_type, active, desc,
                             min_ver, max_ver, self.last_version, visible,
                             userDisabled, appDisabled, softDisabled, foreign,
                             hasBinary, strictCompat, appStrictCompat)

        cur = conn.cursor()
        cur.execute("select internal_id, id, location, version, type, defaultLocale, " + \
                    "visible, active, userDisabled, appDisabled, softDisabled, " + \
                    "isForeignInstall, hasBinaryComponents, strictCompatibility from addon")
        rows = cur.fetchall()
        for row in rows:
            extension = get_extension_from_row(row)
            if extension.ext_type == "extension":
                storage_array = self.extensions
            elif extension.ext_type == "locale":
                storage_array = self.locales
            elif extension.ext_type == "theme":
                storage_array = self.themes
            else:
                raise ExtensionTypeNotRecognised(extension.type, extension.ext_id)

            if not extension.location in storage_array:
                storage_array[extension.location] = []
            storage_array[extension.location].append(extension)

        os.remove(tmp_db)

    def _do_dump(self, storage_array):
        if self.extensions == None:
            return "extensions.sqlite corrupt or missing"

        ret = ""
        for location in storage_array:
            ret += "Location: " + location + "\n\n"
            for extension in storage_array[location]:
                prefix = "  (Inactive) " if not extension.active else ""
                ret += '\t%s%s\n' % (prefix, extension.dump())
            ret += "\n\n\n"
        return ret

    @property
    def running(self):
        if not hasattr(self, '_running'):
            # We detect if this profile is running or not by trying to lock the lockfile
            # If we can't lock it, then Firefox is running
            fd = os.open(os.path.join(self.path, ".parentlock"), os.O_WRONLY|os.O_CREAT|os.O_TRUNC, 0o666)
            lock = struct.pack("hhqqi", 1, 0, 0, 0, 0)
            try:
                fcntl.fcntl(fd, fcntl.F_SETLK, lock)
                self._running = False
                # If we acquired the lock, ensure that we unlock again immediately
                lock = struct.pack("hhqqi", 2, 0, 0, 0, 0)
                fcntl.fcntl(fd, fcntl.F_SETLK, lock)
            except:
                self._running = True

        return self._running

    def dump_extensions(self):
        return self._do_dump(self.extensions)

    def dump_locales(self):
        return self._do_dump(self.locales)

    def dump_themes(self):
        return self._do_dump(self.themes)

    def dump_prefs(self):
        ret = ''
        for pref in self.prefs:
            if type(self.prefs[pref].value) == int:
                value = str(self.prefs[pref].value)
            elif type(self.prefs[pref].value) == bool:
                value = 'true' if self.prefs[pref].value == True else 'false'
            else:
                value = "\"%s\"" % self.prefs[pref].value
            ret += pref + ': ' + value + ' (' + self.prefs[pref].anon_source + ')\n'
        return ret

    def dump_pref_sources(self):
        ret = ''
        for source in self.prefs.pref_sources:
            ret += anonymize_path(source, self.path) + '\n'
        return ret

    def dump_pref_errors(self):
        ret = ''
        for source in self.prefs.errors:
            ret += self.prefs.errors[source] + '\n'
        return ret

    def dump_plugins(self):
        if self.plugins.error != None:
            return "pluginreg.dat exists but isn't parseable. %s" % self.plugins.error

        ret = ''
        for plugin in self.plugins:
            ret += plugin.dump() + '\n'
        return ret

    def get_plugin_packages(self, pkglist):
        if self.plugins.error != None:
            return None

        for plugin in self.plugins:
            if plugin.package != None and plugin.package not in pkglist:
                pkglist.append(plugin.package)

    @property
    def current(self):
        return True if self.appini.buildid == self.last_buildid or self.appini.buildid == None else False

    @property
    def has_active_but_incompatible_extensions(self):
        if self.last_version == None or self.extensions == None:
            return False
        for storage_array in self.extensions, self.locales, self.themes:
            for location in storage_array:
                for extension in storage_array[location]:
                    if extension.active_but_incompatible:
                        return True
        return False

    def dump_active_but_incompatible_extensions(self):
        if self.last_version == None or self.extensions == None:
            return "Unavailable (corrupt or non-existant compatibility.ini or extensions.sqlite)"
        res = ''
        for storage_array in self.extensions, self.locales, self.themes:
            for location in storage_array:
                for extension in storage_array[location]:
                    if extension.active_but_incompatible:
                        res += extension.desc + " - " + extension.ext_id + "\n"
        return res

    def dump_files_with_broken_permissions(self):
        broken = []
        blacklist = [
            r'^lock$'
        ]

        for dirpath, dirnames, filenames in os.walk(self.path):

            def check_path(path):
                relpath = os.path.relpath(path, self.path)
                for i in blacklist:
                    if re.match(i, relpath):
                        return

                flags = os.R_OK | os.W_OK
                if os.path.isdir(path):
                    flags |= os.X_OK
                if not os.access(path, flags):
                    broken.append(relpath)

            check_path(dirpath)
            for name in filenames:
                check_path(os.path.join(dirpath, name))

        uid = os.getuid()
        broken.sort()
        broken_txt = ''
        for file in broken:
            fstat = os.stat(os.path.join(self.path, file))
            summary = "%#o" % (fstat.st_mode & (stat.S_IRWXU | stat.S_IRWXG |
                                                stat.S_IRWXO))
            if fstat.st_uid != uid:
                summary += ', wrong owner'
            broken_txt += file + ' (' + summary + ')\n'

        return broken_txt

    @property
    def has_forced_layers_acceleration(self):
        if "layers.acceleration.force-enabled" in self.prefs and self.prefs["layers.acceleration.force-enabled"].value == "true":
            return True

        return False

    @property
    def compatini(self):
        if not hasattr(self, '_compatini'):
            self._compatini = CompatINIParser(self.path)
        return self._compatini

    @property
    def last_version(self):
        return self.compatini.last_version

    @property
    def last_buildid(self):
        return self.compatini.last_buildid

    @property
    def addon_compat_check_disabled(self):
        is_nightly = re.sub(r'^[^\.]+\.[0-9]+([a-z0-9]*).*', r'\1', self.last_version) == 'a1'
        if is_nightly == True:
            pref = "extensions.checkCompatibility.nightly"
        else:
            pref = "extensions.checkCompatibility.%s" % re.sub(r'(^[^\.]+\.[0-9]+[a-z]*).*', r'\1', self.last_version)
        return pref in self.prefs and self.prefs[pref].value == 'false'


class Profiles:
    '''Small class to build an array of profiles from a profile.ini.
       Can be accessed like a normal array'''
    def __init__(self, ini_file, appini):
        self.profiles = []

        parser = ConfigParser()
        parser.read(ini_file)
        profile_folder = os.path.dirname(ini_file)

        for section in parser.sections():
            if section == "General": continue
            if not parser.has_option(section, "Path"): continue
            path = parser.get(section, "Path")
            name = parser.get(section, "Name")
            is_default = True if parser.has_option(section, "Default") and parser.getint(section, "Default") == 1 else False
            self.profiles.append(Profile(section, name, os.path.join(profile_folder, path), is_default, appini))

        # No "Default" entry when there is one profile
        if len(self) == 1: self[0].default = True

    def __getitem__(self, key):
        if key > len(self) - 1:
            raise IndexError
        return self.profiles[key]

    def __iter__(self):

        class ProfilesIter:
            def __init__(self, profiles):
                self.profiles = profiles
                self.index = 0

            def __next__(self):
                if self.index == len(self.profiles):
                    raise StopIteration
                res = self.profiles[self.index]
                self.index += 1
                return res

            def next(self):
                return self.__next__()

        return ProfilesIter(self)

    def __len__(self):
        return len(self.profiles)

    def dump_profile_summaries(self):
        res = ''
        for profile in self:
            running = " (In use)" if profile.running == True else ""
            default = " (Default)" if profile.default else ""
            outdated = " (Out of date)" if not profile.current else ""
            res += "%s%s - LastVersion=%s/%s%s%s\n" % (profile.id, default, profile.last_version, profile.last_buildid, running, outdated)
        return res


def recent_kernlog(pattern):
    '''Extract recent messages from kern.log or message which match a regex.
       pattern should be a "re" object.  '''
    lines = ''
    if os.path.exists('/var/log/kern.log'):
        file = '/var/log/kern.log'
    elif os.path.exists('/var/log/messages'):
        file = '/var/log/messages'
    else:
        return lines

    for line in open(file):
        if pattern.search(line):
            lines += line
    return lines


def recent_auditlog(pattern):
    '''Extract recent messages from kern.log or message which match a regex.
       pattern should be a "re" object.  '''
    lines = ''
    if os.path.exists('/var/log/audit/audit.log'):
        file = '/var/log/audit/audit.log'
    else:
        return lines

    for line in open(file):
        if pattern.search(line):
            lines += line
    return lines


def add_info(report, ui):
    '''Entry point for apport'''

    def populate_item(key, data):
        if data != None and data.strip() != '':
            report[key] = data

    def append_tag(tag):
        tags = report.get('Tags', '')
        if tags:
            tags += ' '
        report['Tags'] = tags + tag

    ddproc = Popen(['dpkg-divert', '--truename', '/usr/bin/firefox'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
    truename = ddproc.communicate()
    if ddproc.returncode == 0 and truename[0].strip() != '/usr/bin/firefox':
        ddproc = Popen(['dpkg-divert', '--listpackage', '/usr/bin/firefox'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
        diverter = ddproc.communicate()
        report['UnreportableReason'] = "/usr/bin/firefox has been diverted by a third party package (%s)" % diverter[0].strip()
        return

    conf_dir = os.path.join(os.environ["HOME"], ".mozilla", "firefox")
    appini = AppINIParser('/usr/lib/firefox')
    populate_item("BuildID", appini.buildid)

    profiles = Profiles(os.path.join(conf_dir, "profiles.ini"), appini)
    populate_item("Profiles", profiles.dump_profile_summaries())
    if len(profiles) == 0: report["NoProfiles"] = 'True'

    for profile in profiles:
        if profile.running and not profile.current:
            report["UnreportableReason"] = "Firefox has been upgraded since you started it. Please restart all instances of Firefox and try again"
            return

    seen_default = False
    running_incompatible_addons = False
    forced_layers_accel = False
    addon_compat_check_disabled = False
    for profile in profiles:
        if profile.default and not seen_default and len(profiles) > 1:
            prefix = 'DefaultProfile'
            seen_default = True
        elif len(profiles) > 1:
            prefix = profile.id
        else:
            prefix = ''

        populate_item(prefix + "Extensions", profile.dump_extensions())
        populate_item(prefix + "Locales", profile.dump_locales())
        populate_item(prefix + "Themes", profile.dump_themes())
        populate_item(prefix + "Plugins", profile.dump_plugins())
        populate_item(prefix + "IncompatibleExtensions", profile.dump_active_but_incompatible_extensions())
        populate_item(prefix + "Prefs", profile.dump_prefs())
        populate_item(prefix + "PrefSources", profile.dump_pref_sources())
        populate_item(prefix + "PrefErrors", profile.dump_pref_errors())
        populate_item(prefix + "BrokenPermissions", profile.dump_files_with_broken_permissions())

        if (profile.current or profile.default) and profile.has_active_but_incompatible_extensions:
            running_incompatible_addons = True
        if (profile.current or profile.default) and profile.has_forced_layers_acceleration:
            forced_layers_accel = True
        if (profile.current or profile.default) and profile.addon_compat_check_disabled:
            addon_compat_check_disabled = True

    crash_reports = []
    report_to_mtime = {}
    most_recent_report = None
    most_recent_mtime = 0
    for crash in glob(os.path.join(conf_dir, 'Crash Reports', 'submitted', '*.txt')):
        id = re.sub(r'\.txt$', '', os.path.basename(crash))
        report_to_mtime[id] = os.stat(crash).st_mtime
        crash_reports.append(id)
        if most_recent_report == None or report_to_mtime[id] > most_recent_mtime:
            most_recent_report = id
            most_recent_mtime = report_to_mtime[id]

    def crashes_sort(a, b):
        if report_to_mtime[b] > report_to_mtime[a]:
            return 1
        elif report_to_mtime[b] < report_to_mtime[a]:
            return -1
        else:
            return 0

    # Put the most recent first
    crash_reports.sort(key=functools.cmp_to_key(crashes_sort))

    crash_reports_str = ''
    i = 0
    for crash in crash_reports:
        crash_reports_str += crash + '\n'
        i += 1
        if i == 15: break

    populate_item('SubmittedCrashIDs', crash_reports_str)
    populate_item('MostRecentCrashID', most_recent_report)            

    plugin_packages = []
    for profile in profiles:
        profile.get_plugin_packages(plugin_packages)
    if len(plugin_packages) > 0: attach_related_packages(report, plugin_packages)

    report["RunningIncompatibleAddons"] = 'True' if running_incompatible_addons == True else 'False'
    report["ForcedLayersAccel"] = 'True' if forced_layers_accel == True else 'False'
    report["AddonCompatCheckDisabled"] = 'True' if addon_compat_check_disabled == True else 'False'

    if 'firefox' == 'firefox-trunk':
        report["Channel"] = 'nightly'
        append_tag('nightly-channel')
        if report["SourcePackage"] == 'firefox-trunk':
            report["SourcePackage"] = 'firefox'
    else:
        channelpref = Prefs(None, ['/usr/lib/firefox/defaults/pref/channel-prefs.js'], whitelist = [ r'app\.update\.channel' ])
        if "app.update.channel" in channelpref:
            report["Channel"] = channelpref["app.update.channel"].value
            append_tag(channelpref["app.update.channel"].value + '-channel')
        else:
            report["Channel"] = 'Unavailable'

    if os.path.exists('/sys/bus/pci'):
        report['Lspci'] = command_output(['lspci','-vvnn'])
    attach_alsa(report)
    attach_network(report)
    attach_wifi(report)

    # Get apparmor stuff if the profile isn't disabled. copied from
    # source_apparmor.py until apport runs hooks via attach_related_packages
    apparmor_disable_dir = "/etc/apparmor.d/disable"
    add_apparmor = True
    if os.path.isdir(apparmor_disable_dir):
        for f in os.listdir(apparmor_disable_dir):
            if f.startswith("usr.bin.firefox"):
                add_apparmor = False
                break
    if add_apparmor:
        attach_related_packages(report, ['apparmor', 'libapparmor1',
            'libapparmor-perl', 'apparmor-utils', 'auditd', 'libaudit0'])

        attach_file(report, '/proc/version_signature', 'ProcVersionSignature')
        attach_file(report, '/proc/cmdline', 'ProcCmdline')

        sec_re = re.compile('audit\(|apparmor|selinux|security', re.IGNORECASE)
        report['KernLog'] = recent_kernlog(sec_re)

        if os.path.exists("/var/log/audit"):
            # this needs to be run as root
            report['AuditLog'] = recent_auditlog(sec_re)


if __name__ == "__main__":
    import apport
    from apport import packaging
    D = {}
    D['Package'] = 'firefox'
    D['SourcePackage'] = 'firefox'
    add_info(D, None)
    for KEY in D.keys():
        print('''-------------------%s: ------------------\n%s''' % (KEY, D[KEY]))
