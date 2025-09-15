{
  pkgs,
  lib,
  config,
  ...
}:
{
  services.dunst = {
    enable = true;

    settings = {
      global = {
        width = "(0 450)";
        offset = "48x60";

        progress_bar_frame_width = 1;
        progress_bar_min_width = 150;
        progress_bar_max_width = 300;
        progress_bar_corner_radius = 0;

        icon_corner_radius = 0;
        indicate_hidden = true;
        transparency = 80;
        separator_height = 2;
        padding = 15;
        horizontal_padding = 15;
        text_icon_padding = 0;
        frame_width = 0;
        gap_size = 0;

        sort = true;
        idle_threshold = 120;
        font = "JetBrainsMono Nerd Font 10";
        line_height = 10;
        markup = "full";
        format = "<b><u>%s</u></b>\n%b\n";
        alignment = "left";
        vertical_alignment = "top";
        show_age_threshold = 60;
        word_wrap = true;
        ellipsize = "end";
        ignore_newline = false;
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = true;
        enable_recursive_icon_lookup = true;
        icon_theme = "Papirus-Dark";
        icon_position = "left";
        min_icon_size = 48;
        max_icon_size = 128;
        sticky_history = true;
        history_length = 50;
        corner_radius = 9;
      };
    };
  };
}
