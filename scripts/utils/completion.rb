#!/usr/bin/ruby
=begin
  Mitchell's completion.rb
  Copyright (c) 2006 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Displays a completion dialog from items in STDIN separated
  by newlines and prints the result to STDOUT
=end

require 'optparse'
opts = {}
OptionParser.new do |o|
  o.banner = "Usage: completion.rb [options]"
  o.on('-n', '--name NAME', 'Dialog name') { |n| opts[:name] = n }
  o.on('-l', '--list', 'Show list') { |l| opts[:list] = l }
end.parse!

require 'gtk2'
Gtk.init

# create model from STDIN (delimited by newlines)
model = Gtk::ListStore.new(String)
$stdin.each_line do |line|
  line.chomp!
  model.append.set_value(0, line) unless line.empty?
end
model.set_sort_column_id(0)

dialog = Gtk::Dialog.new( opts[:name], nil, Gtk::Dialog::MODAL,
  [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK] )
dialog.default_response = Gtk::Dialog::RESPONSE_OK
dialog.set_size_request(300, opts[:list] ? 300 : -1)

completion = Gtk::EntryCompletion.new
completion.model = model
completion.text_column = 0
completion.inline_completion = true
completion.popup_single_match = false

entry = Gtk::Entry.new
entry.activates_default = true
entry.completion = completion
dialog.vbox.pack_start(entry, false, 0, 0)

def entry.goto_line_end
  signal_emit('move-cursor',
    Gtk::MovementStep::PARAGRAPH_ENDS, 1, false)
end

# treeview if list option specified
if opts[:list]
  sw = Gtk::ScrolledWindow.new
  sw.set_policy( Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC )
  view = Gtk::TreeView.new(model)
  view.headers_visible = false
  view.append_column( Gtk::TreeViewColumn.new('',
    Gtk::CellRendererText.new, :text => 0) )
  sw.add(view)
  dialog.vbox.pack_start(sw, true, 0, 5)
  view.signal_connect('row-activated') do |widget, path, column|
    iter = view.model.get_iter(path)
    entry.text = iter[0]
    entry.grab_focus
    entry.goto_line_end
  end

  # move treeview cursor from text entry (ctrl+n/p)
  entry.signal_connect('key-press-event') do |widget, event|
    if event.state == Gdk::Window::ModifierType::CONTROL_MASK
      path = view.cursor.first
      case event.keyval
      when Gdk::Keyval::GDK_n, Gdk::Keyval::GDK_p
        unless path.nil?
          event.keyval == Gdk::Keyval::GDK_n ?
            path.next! : path.prev!
        else
          path = Gtk::TreePath.new(0)
        end
        iter = view.model.get_iter(path)
        if iter
          entry.text = iter[0]
          view.set_cursor(path, nil, false)
          entry.goto_line_end
        end
      end
    end
  end

  # move cursor to item that matches entry text
  def update_view(view, entry)
    view.model.each do |model, path, iter|
      if iter[0] == entry.text
        view.set_cursor(path, nil, false)
        return
      end
    end
    view.set_cursor( Gtk::TreePath.new(0), nil, false )
  end

  # by default if entry text cannot be matched, go here
  iter = model.insert(0)
  iter[0] = ''
  view.set_cursor( Gtk::TreePath.new(0), nil, false )
end

accel = Gtk::AccelGroup.new
accel.connect(Gdk::Keyval::GDK_Escape, 0, Gtk::ACCEL_VISIBLE) do
  dialog.signal_emit('response', Gtk::Dialog::RESPONSE_CANCEL)
end
dialog.add_accel_group(accel)

# upon an attempted tab-completion, stop focus from changing,
# put focus back on entry, re-display completion dropdown
# (requires entry text modification to fire)
entry.signal_connect('focus-out-event') do
  entry.grab_focus
  entry.goto_line_end
  entry.signal_emit('insert-at-cursor', ' ')
  entry.signal_emit('backspace')
  completion.complete
  update_view(view, entry) if opts[:list]
end

dialog.signal_connect('response') do |widget, signal|
  $stdout.print entry.text if signal == Gtk::Dialog::RESPONSE_OK
  $stdout.print '*cancelled*' if signal == Gtk::Dialog::RESPONSE_CANCEL
  dialog.destroy
  Gtk.main_quit
end

dialog.show_all

Gtk.main
