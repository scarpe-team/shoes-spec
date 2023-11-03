# Shoes cNative Drawables

In Shoes3, a lot of types (e.g. Shoes::Types::Button, Shoes::Types::ListBox, Shoes::Types::Check) inherit from
the Shoes::Types::Native (cNative) class. Anything that does inherits a list of methods from Native:

~~~c
    rb_define_method(cNative, "app", CASTHOOK(shoes_canvas_get_app), 0);
    rb_define_method(cNative, "parent", CASTHOOK(shoes_control_get_parent), 0);
    rb_define_method(cNative, "style", CASTHOOK(shoes_control_style), -1);
    rb_define_method(cNative, "displace", CASTHOOK(shoes_control_displace), 2);
    rb_define_method(cNative, "focus", CASTHOOK(shoes_control_focus), 0);
    rb_define_method(cNative, "hide", CASTHOOK(shoes_control_hide), 0);
    rb_define_method(cNative, "show", CASTHOOK(shoes_control_show), 0);
    rb_define_method(cNative, "state=", CASTHOOK(shoes_control_set_state), 1);
    rb_define_method(cNative, "state", CASTHOOK(shoes_control_get_state), 0);
    rb_define_method(cNative, "move", CASTHOOK(shoes_control_move), 2);
    rb_define_method(cNative, "top", CASTHOOK(shoes_control_get_top), 0);
    rb_define_method(cNative, "left", CASTHOOK(shoes_control_get_left), 0);
    rb_define_method(cNative, "width", CASTHOOK(shoes_control_get_width), 0);
    rb_define_method(cNative, "height", CASTHOOK(shoes_control_get_height), 0);
    rb_define_method(cNative, "remove", CASTHOOK(shoes_control_remove), 0);
~~~

