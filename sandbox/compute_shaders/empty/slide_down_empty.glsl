#version 460

#include "../includes.glsl"

// Slide down left on empty kernel
void cellular_automata_slide_left_empty(ivec2 pos) {
  Matter current = read_matter(pos);
  Matter down = get_neighbor(pos, DOWN);
  Matter right = get_neighbor(pos, RIGHT);
  Matter up_right = get_neighbor(pos, UP_RIGHT);
  Matter down_left = get_neighbor(pos, DOWN_LEFT);

  Matter m = current;
  if(!is_at_border_top(pos) && !is_at_border_right(pos) && slides_on_empty(up_right, current, right)) {
    m = up_right;
  } else if(!is_at_border_bottom(pos) && !is_at_border_left(pos) &&
            slides_on_empty(current, down_left, down)) {
    m = down_left;
  }
  write_matter(pos, m);
}

// Slide down right on empty kernel
void cellular_automata_slide_right_empty(ivec2 pos) {
  Matter current = read_matter(pos);
  Matter down = get_neighbor(pos, DOWN);
  Matter left = get_neighbor(pos, LEFT);
  Matter up_left = get_neighbor(pos, UP_LEFT);
  Matter down_right = get_neighbor(pos, DOWN_RIGHT);

  Matter m = current;
  if(!is_at_border_top(pos) && !is_at_border_left(pos) && slides_on_empty(up_left, current, left)) {
    m = up_left;
  } else if(!is_at_border_bottom(pos) && !is_at_border_right(pos) &&
            slides_on_empty(current, down_right, down)) {
    m = down_right;
  }
  write_matter(pos, m);
}

void cellular_automata_slide_down_empty(ivec2 pos) {
  if((push_constants.sim_steps + push_constants.move_step) % 2 == 0) {
    cellular_automata_slide_left_empty(pos);
  } else {
    cellular_automata_slide_right_empty(pos);
  }
}

void main() { cellular_automata_slide_down_empty(get_current_sim_pos()); }