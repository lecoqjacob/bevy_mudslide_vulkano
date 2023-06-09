#version 450

#include "includes.glsl"

vec4 vary_color_rgb(vec4 color, ivec2 seed_pos) {
  // Just use the same seed (means same color for individual xy position)
  float seed = 0.1;
  float p = rand(seed_pos, seed);
  float variation = -0.1 + 0.15 * p;
  color.rgb += vec3(variation);
  return color;
}

// 3. Convert uint to vec4, randomize rgb a bit, convert back
uint variate_color(ivec2 pos, uint color) {
  vec4 color_f32 = matter_color_to_vec4(color);
  vec4 variated_color_f32 = vary_color_rgb(color_f32, pos);
  uint rgb = ((uint(variated_color_f32.r * 255.0) & uint(255)) << uint(16)) |
             ((uint(variated_color_f32.g * 255.0) & uint(255)) << uint(8)) |
             (uint(variated_color_f32.b * 255.0) & uint(255));
  return rgb;
}

// 2. Check if current pixel is within radius from draw position (closest point
// on line)
void draw_matter_circle(ivec2 pos, ivec2 draw_pos, float radius, Matter matter) {
  int y_start = draw_pos.y - int(radius);
  int y_end = draw_pos.y + int(radius);
  int x_start = draw_pos.x - int(radius);
  int x_end = draw_pos.x + int(radius);
  if(pos.x >= x_start && pos.x <= x_end && pos.y >= y_start && pos.y <= y_end) {
    vec2 diff = vec2(pos) - vec2(draw_pos);
    float dist = length(diff);
    if(round(dist) <= radius) {
      // 3. Vary color only if not empty
      if(!is_empty(matter)) { matter.color = variate_color(pos, matter.color); }

      // 4. write matter to input buffer
      write_matter_input(pos, matter);
    }
  }
}

void draw_matter_square(ivec2 pos, ivec2 draw_pos, int size, Matter matter) {
  int y_start = draw_pos.y - size / 2;
  int y_end = draw_pos.y + size / 2;
  int x_start = draw_pos.x - size / 2;
  int x_end = draw_pos.x + size / 2;
  if(pos.x >= x_start && pos.x <= x_end && pos.y >= y_start && pos.y <= y_end) {
    // 3. Vary color only if not empty
    if(!is_empty(matter)) { matter.color = variate_color(pos, matter.color); }

    // 4. write matter to input buffer
    write_matter_input(pos, matter);
  }
}

// Line v->w, point p
// https://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment
vec2 closest_point_on_line(vec2 v, vec2 w, vec2 p) {
  vec2 c = v - w;
  // length squared
  float l2 = dot(c, c);
  if(l2 == 0.0) { return v; }
  float t = max(0.0, min(1.0, dot(p - v, w - v) / l2));
  vec2 projection = v + t * (w - v);
  return projection;
}

void main() {
  ivec2 pos = get_current_sim_pos();

  // 1. Get closest point on the line defined by start and end from push
  // constants
  vec2 point_on_line = closest_point_on_line(push_constants.draw_pos_start, push_constants.draw_pos_end, pos);

  uint matter_at = read_matter(pos).matter;
  uint draw = new_matter(push_constants.draw_matter).matter;

  // Make sure we don't draw on top of other matter, unless we are erasing
  if(matter_at == empty_matter || draw == empty_matter) {
    // 2. Draw matter at the closest point on line
    if(push_constants.is_square) {
      draw_matter_square(pos, ivec2(point_on_line), int(push_constants.draw_radius * 2.0),
                         new_matter(push_constants.draw_matter));
    } else {
      draw_matter_circle(pos, ivec2(point_on_line), push_constants.draw_radius,
                         new_matter(push_constants.draw_matter));
    }
  }
}