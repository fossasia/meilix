#!/usr/bin/python
from gi.repository import Gtk
from gi.repository import Gio
import sys
import os
import subprocess

class SystemLock(Gtk.Application):
    lock = True
    command = 0    
    message = Gtk.Dialog()  
    def do_activate(self):
        window = Gtk.Window(application=self)
        window.set_title("System Lock")       
        self.initWindow(window)
        window.show_all()   
    def initWindow(self,window):
        window.set_default_size(300,200)
        window.set_resizable(False)
        #window.set_margin_top(50)
        #window.set_margin_bottom(50)
        main = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        box1 = Gtk.Box(spacing=6)        
        freeze = Gtk.RadioButton(label="Freeze System")
        freeze.connect("toggled",self.toggled_radio_lock)
        ufreeze = Gtk.RadioButton.new_from_widget(freeze)        
        ufreeze.set_label("Unfreeze System")
        ufreeze.connect("toggled",self.toggled_radio_unlock)
        box2 = Gtk.Box(spacing=6)
        save = Gtk.Button(label = "Save")
        save.connect("clicked",self.on_save_clicked)
        cancel = Gtk.Button(label ="Cancel")
        cancel.connect("clicked",self.on_cancel_clicked)
        box2.add(cancel)
        box2.add(save)
        main.set_margin_left(20)
        main.set_margin_top(20)
        main.set_margin_right(20)
        main.set_margin_bottom(20)        
        main.add(freeze)
        main.add(ufreeze)
        status = self.check_freeze()
        main.add(Gtk.Label("Status: "+status))
        main.add(box2)
        window.add(main)
        window.set_default_icon_from_file("/etc/system-lock/lock-icon.png")
        window.set_position(Gtk.WindowPosition.CENTER)
        self.message_dialog();
    def toggled_radio_lock(self,button):
        if button.get_active():
            self.lock = True
        else:
            self.lock = False
    def toggled_radio_unlock(self,button):
        if button.get_active():
            self.lock = False
        else:
            self.lock = True
    def check_freeze(self):
        if (os.path.exists("/etc/.ofris")):
            return "System is locked"
        else:
            return "System is not locked"
    def on_save_clicked(self,widget):
        if self.lock:            
            #win = self.create_spinner()
            #win.show_all()
            
            #self.spin = Gtk.Spinner();
            #self.spin.start()
            #self.add(self.spin)            
            #subprocess.call(['gksu','sh lock.sh'])
            self.command = 0
            #self.message_dialog()
            #win.destroy()
            self.message.show_all()
        else:
            self.command = 1
            self.message.show_all()
            #self.message_dialog()
            #subprocess.call(['gksu','sh unlock.sh'])
    def message_dialog(self): 		     
        content_area = self.message.get_content_area()        
        content_area.add(Gtk.Label("You need to restart the computer for the change to take effect."))
        self.message.add_button(button_text="Cancel",response_id=Gtk.ResponseType.CANCEL)
        self.message.add_button(button_text="Save and Restart",response_id=Gtk.ResponseType.OK)
        self.message.connect("response", self.on_response)
        #self.message.show_all()
    def on_response(self, widget, response_id):        
        # destroy the widget (the dialog) when the function on_response() is called
        if (response_id == Gtk.ResponseType.CANCEL):
            widget.hide()
        elif response_id == Gtk.ResponseType.OK:
           # win = self.create_spinner()            
            #win.show_all()            
            if (self.command == 0):
                subprocess.Popen(['gksu','sh /etc/system-lock/lock.sh'])                
                #win.destroy();
            else:
                subprocess.Popen(['gksu','sh /etc/system-lock/unlock.sh'])
            #win.destroy();
            widget.hide()
            #//p.communicate()
    def create_spinner(self):
        win = Gtk.Window();        
        win.set_default_size(100,50)        
        main = Gtk.Box(orientation=Gtk.Orientation.VERTICAL,spacing=6)
        main.set_margin_left(10)
        main.set_margin_top(10)
        main.set_margin_right(10)
        main.set_margin_bottom(10)       
        win.set_position(Gtk.WindowPosition.CENTER)
        win.set_decorated(False)
        win.set_keep_above(True)
        win.set_skip_taskbar_hint(True)
        win.set_modal(True)                    
        label = Gtk.Label();
        label.set_markup("<big>Please Wait !</big>");
        main.add(label)        
        win.add(main)
        self.message.destroy()
        return win
    def on_cancel_clicked(self,widget):
        sys.exit()
app = SystemLock();
exit_status = app.run(sys.argv)
sys.exit(exit_status)
