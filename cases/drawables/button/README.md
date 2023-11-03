# Button

In Shoes3, the button had the following method init:

void shoes_button_init() {
    cButton  = rb_define_class_under(cTypes, "Button", cNative);
    rb_define_method(cButton, "draw", CASTHOOK(shoes_button_draw), 2);
    rb_define_method(cButton, "click", CASTHOOK(shoes_control_click), -1);
    rb_define_method(cButton, "tooltip", CASTHOOK(shoes_control_get_tooltip), 0);
    rb_define_method(cButton, "tooltip=", CASTHOOK(shoes_control_set_tooltip), 1);
    RUBY_M("+button", button, -1);
}

It inherits from cNative, so it has other methods as well.

