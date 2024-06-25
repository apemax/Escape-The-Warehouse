def tick args
  args.state.current_scene ||= :title_scene

  current_scene = args.state.current_scene

  case current_scene
  when :title_scene
    tick_title_scene args
  when :game_scene
    tick_game_scene args
  when :game_over_scene
    tick_game_over_scene args
  when :game_win_scene
    tick_game_win_scene args
  end

  if args.state.current_scene != current_scene
    raise "Scene was changed incorrectly. Set args.state.next_scene to change scenes."
  end

  if args.state.next_scene
    args.state.current_scene = args.state.next_scene
    args.state.next_scene = nil
  end
end

def tick_title_scene args
  args.outputs.background_color = [0, 0, 0]
  args.outputs.labels << [280, 670, "Escape the warehouse!", 30, 255, 255, 255, 255]
  args.outputs.labels << [390, 500, "Press the Enter key to start.", 10, 255, 255, 255, 255]
  args.outputs.labels << [570, 400, "Controls:", 10, 255, 255, 255, 255]
  args.outputs.labels << [160, 265, "w, s, a, d or arrow keys = Move up, down, left, right.", 10, 255, 255, 255, 255]

  if args.inputs.keyboard.enter
    args.state.next_scene = :game_scene
  end
end

def tick_game_scene args
  args.state.player ||= {x: 10, y: 360, dx: 0, dy: 0, w: 48, h: 32, path: 'sprites/playerbox.png', cooldown: 0}
  args.state.shelves ||= []
  args.state.boxes ||= []
  args.state.sentry_robots ||= []
  args.state.sentry_robot_detection_fields ||= []
  args.state.security_cameras ||= []
  args.state.security_camera_detection_fields ||=[]
  args.state.alert ||= 0
  args.state.alert_robots ||= []
  args.state.alert_robot_detection_fields ||= []
  args.state.alert_light ||= []
  args.state.goal ||= {x: 1232, y: 360, w: 48, h: 48, path: 'sprites/exit.png'}
  args.state.frames ||= 0
  args.state.time_seconds ||= 0
  args.state.debug_enabled ||= false

  args.state.frames += 1

  if args.state.frames == 59
    args.state.frames = 0
    args.state.time_seconds += 1
  end

  if args.state.shelves.empty?
    args.state.shelves = make_shelves
  end

  if args.state.boxes.empty?
    args.state.boxes = make_boxes
  end

  if args.state.sentry_robots.empty?
    args.state.sentry_robots = make_sentry_robots
  end

  if args.state.sentry_robot_detection_fields.empty?
    args.state.sentry_robot_detection_fields = make_sentry_robot_detection_fields
  end

  if args.state.alert_robots.empty? && args.state.alert == 1
    args.state.alert_robots = make_alert_robots
  end

  if args.state.alert_robot_detection_fields.empty? && args.state.alert == 1
    args.state.alert_robot_detection_fields = make_alert_robot_detection_fields
  end

  if args.state.alert_light.empty?
    args.state.alert_light = make_alert_light args
  end

  if args.state.security_cameras.empty?
    args.state.security_cameras = make_security_cameras
  end

  if args.state.security_camera_detection_fields.empty?
    args.state.security_camera_detection_fields = make_security_camera_detection_fields
  end

  if args.state.debug_enabled
    debug args
  end

  if args.inputs.keyboard.p
    args.state.debug_enabled = true
  end
  if args.inputs.keyboard.o
    args.state.debug_enabled = false
  end

  args.state.player.dx = args.inputs.left_right * 3
  args.state.player.dy = args.inputs.up_down * 3

  args.state.player.x += args.state.player.dx

  collision_shelves = args.state.shelves.find { |t| t.intersect_rect? args.state.player }

  if collision_shelves
    if args.state.player.dx > 0
      args.state.player.x = collision_shelves.x - args.state.player.w
    elsif args.state.player.dx < 0
      args.state.player.x = collision_shelves.x + collision_shelves.w
    end
    args.state.player.dx = 0
  end

  collision_boxes = args.state.boxes.find { |t| t.intersect_rect? args.state.player }

  if collision_boxes
    if args.state.player.dx > 0
      args.state.player.x = collision_boxes.x - args.state.player.w
    elsif args.state.player.dx < 0
      args.state.player.x = collision_boxes.x + collision_boxes.w
    end
    args.state.player.dx = 0
  end

  args.state.player.y += args.state.player.dy

  collision_shelves = args.state.shelves.find { |t| t.intersect_rect? args.state.player }

  if collision_shelves
    if args.state.player.dy > 0
      args.state.player.y = collision_shelves.y - args.state.player.h
    elsif args.state.player.dy < 0
      args.state.player.y = collision_shelves.y + collision_shelves.h
    end
    args.state.player.dy = 0
  end

  collision_boxes = args.state.boxes.find { |t| t.intersect_rect? args.state.player }

  if collision_boxes
    if args.state.player.dy > 0
      args.state.player.y = collision_boxes.y - args.state.player.h
    elsif args.state.player.dy < 0
      args.state.player.y = collision_boxes.y + collision_boxes.h
    end
    args.state.player.dy = 0
  end

  if args.state.player[:x] <= 0
    args.state.player[:x] = 0
  end
  if args.state.player[:x] >= 1232
    args.state.player[:x] = 1232
  end
  if args.state.player[:y] <= 0
    args.state.player[:y] = 0
  end
  if args.state.player[:y] >= 688
    args.state.player[:y] = 688
  end

  args.state.sentry_robots.each do |robot|
    if robot.intersect_rect? args.state.player
      args.state.next_scene = :game_over_scene
    end
    if robot[:id] == 1
      if robot[:x] > 700 && robot[:y] == 680
        robot[:x] -= 1
      end
      if robot[:y] > 10 && robot[:x] == 700
        robot[:y] -= 1
      end
      if robot[:x] < 1160 && robot[:y] == 10
        robot[:x] += 1
      end
      if robot[:y] < 680 && robot[:x] == 1160
        robot[:y] += 1
      end
    end
    if robot[:id] == 2
      if robot[:x] < 640 && robot[:y] == 10
        robot[:x] += 1
      end
      if robot[:y] < 680 && robot[:x] == 640
        robot[:y] += 1
      end
      if robot[:x] > 190 && robot[:y] == 680
        robot[:x] -= 1
      end
      if robot[:y] > 10 && robot[:x] == 190
        robot[:y] -= 1
      end
    end
    if robot[:id] == 3
      if robot[:x] > 700 && robot[:y] == 680
        robot[:x] -= 1
      end
      if robot[:y] > 10 && robot[:x] == 700
        robot[:y] -= 1
      end
      if robot[:x] < 1160 && robot[:y] == 10
        robot[:x] += 1
      end
      if robot[:y] < 680 && robot[:x] == 1160
        robot[:y] += 1
      end
    end
    if robot[:id] == 4
      if robot[:x] < 640 && robot[:y] == 10
        robot[:x] += 1
      end
      if robot[:y] < 680 && robot[:x] == 640
        robot[:y] += 1
      end
      if robot[:x] > 190 && robot[:y] == 680
        robot[:x] -= 1
      end
      if robot[:y] > 10 && robot[:x] == 190
        robot[:y] -= 1
      end
    end
    args.state.alert_light.each do |light|
      if robot[:id] == 1 && light[:id] == 1
        if robot[:x] > 700 && robot[:y] == 680
          light[:x] -= 1
        end
        if robot[:y] > 10 && robot[:x] == 700
          light[:y] -= 1
        end
        if robot[:x] < 1160 && robot[:y] == 10
          light[:x] += 1
        end
        if robot[:y] < 680 && robot[:x] == 1160
          light[:y] += 1
        end
      end
      if robot[:id] == 2 && light[:id] == 2
        if robot[:x] < 640 && robot[:y] == 10
          light[:x] += 1
        end
        if robot[:y] < 680 && robot[:x] == 640
          light[:y] += 1
        end
        if robot[:x] > 190 && robot[:y] == 680
          light[:x] -= 1
        end
        if robot[:y] > 10 && robot[:x] == 190
          light[:y] -= 1
        end
      end
      if robot[:id] == 3 && light[:id] == 3
        if robot[:x] > 700 && robot[:y] == 680
          light[:x] -= 1
        end
        if robot[:y] > 10 && robot[:x] == 700
          light[:y] -= 1
        end
        if robot[:x] < 1160 && robot[:y] == 10
          light[:x] += 1
        end
        if robot[:y] < 680 && robot[:x] == 1160
          light[:y] += 1
        end
      end
      if robot[:id] == 4 && light[:id] == 4
        if robot[:x] < 640 && robot[:y] == 10
          light[:x] += 1
        end
        if robot[:y] < 680 && robot[:x] == 640
          light[:y] += 1
        end
        if robot[:x] > 190 && robot[:y] == 680
          light[:x] -= 1
        end
        if robot[:y] > 10 && robot[:x] == 190
          light[:y] -= 1
        end
      end
    end
  end

  args.state.alert_robots.each do |robot|
    if robot.intersect_rect? args.state.player
      args.state.next_scene = :game_over_scene
    end
    if robot[:id] == 1
      if robot[:x] < 1160 && robot[:y] == 10
        robot[:x] += 1
      end
      if robot[:y] < 680 && robot[:x] == 1160
        robot[:y] += 1
      end
      if robot[:x] > 190 && robot[:y] == 680
        robot[:x] -= 1
      end
      if robot[:y] > 10 && robot[:x] == 190
        robot[:y] -= 1
      end
    end
    if robot[:id] == 2
      if robot[:x] < 1160 && robot[:y] == 10
        robot[:x] += 1
      end
      if robot[:y] < 680 && robot[:x] == 1160
        robot[:y] += 1
      end
      if robot[:x] > 190 && robot[:y] == 680
        robot[:x] -= 1
      end
      if robot[:y] > 10 && robot[:x] == 190
        robot[:y] -= 1
      end
    end
    args.state.alert_light.each do |light|
      if robot[:id] == 1 && light[:id] == 5
        if robot[:x] < 1160 && robot[:y] == 10
          light[:x] += 1
        end
        if robot[:y] < 680 && robot[:x] == 1160
          light[:y] += 1
        end
        if robot[:x] > 190 && robot[:y] == 680
          light[:x] -= 1
        end
        if robot[:y] > 10 && robot[:x] == 190
          light[:y] -= 1
        end
      end
      if robot[:id] == 2  && light[:id] == 6
        if robot[:x] < 1160 && robot[:y] == 10
          light[:x] += 1
        end
        if robot[:y] < 680 && robot[:x] == 1160
          light[:y] += 1
        end
        if robot[:x] > 190 && robot[:y] == 680
          light[:x] -= 1
        end
        if robot[:y] > 10 && robot[:x] == 190
          light[:y] -= 1
        end
      end
    end
  end

  args.state.sentry_robots.each do |robot|
    args.state.sentry_robot_detection_fields.each do |field|
      if robot[:id] == 1 && field[:id] == 1
        if robot[:x] > 700 && robot[:y] == 680
          field[:x] -= 1
          if field[:direction] == 11
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:y] > 10 && robot[:x] == 700
          field[:y] -= 1
          if field[:direction] == 12
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:x] < 1160 && robot[:y] == 10
          field[:x] += 1
          if field[:direction] == 13
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:y] < 680 && robot[:x] == 1160
          field[:y] += 1
          if field[:direction] == 14
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
      end
      if robot[:id] == 2 && field[:id] == 2
        if robot[:x] < 640 && robot[:y] == 10
          field[:x] += 1
          if field[:direction] == 21
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:y] < 680 && robot[:x] == 640
          field[:y] += 1
          if field[:direction] == 22
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:x] > 190 && robot[:y] == 680
          field[:x] -= 1
          if field[:direction] == 23
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:y] > 10 && robot[:x] == 190
          field[:y] -= 1
          if field[:direction] == 24
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
      end
      if robot[:id] == 3 && field[:id] == 3
        if robot[:x] > 700 && robot[:y] == 680
          field[:x] -= 1
          if field[:direction] == 31
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:y] > 10 && robot[:x] == 700
          field[:y] -= 1
          if field[:direction] == 32
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:x] < 1160 && robot[:y] == 10
          field[:x] += 1
          if field[:direction] == 33
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:y] < 680 && robot[:x] == 1160
          field[:y] += 1
          if field[:direction] == 34
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
      end
      if robot[:id] == 4 && field[:id] == 4
        if robot[:x] < 640 && robot[:y] == 10
          field[:x] += 1
          if field[:direction] == 41
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:y] < 680 && robot[:x] == 640
          field[:y] += 1
          if field[:direction] == 42
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:x] > 190 && robot[:y] == 680
          field[:x] -= 1
          if field[:direction] == 43
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:y] > 10 && robot[:x] == 190
          field[:y] -= 1
          if field[:direction] == 44
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
      end
    end
  end

  args.state.alert_robots.each do |robot|
    args.state.alert_robot_detection_fields.each do |field|
      if robot[:id] == 1 && field[:id] == 1
        if robot[:x] < 1160 && robot[:y] == 10
          field[:x] += 1
          if field[:direction] == 11
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:y] < 680 && robot[:x] == 1160
          field[:y] += 1
          if field[:direction] == 12
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:x] > 190 && robot[:y] == 680
          field[:x] -= 1
          if field[:direction] == 13
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:y] > 10 && robot[:x] == 190
          field[:y] -= 1
          if field[:direction] == 14
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
      end
      if robot[:id] == 2 && field[:id] == 2
        if robot[:x] < 1160 && robot[:y] == 10
          field[:x] += 1
          if field[:direction] == 21
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:y] < 680 && robot[:x] == 1160
          field[:y] += 1
          if field[:direction] == 22
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:x] > 190 && robot[:y] == 680
          field[:x] -= 1
          if field[:direction] == 23
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
        if robot[:y] > 10 && robot[:x] == 190
          field[:y] -= 1
          if field[:direction] == 24
            args.outputs.primitives << field
            if field.intersect_rect? args.state.player
              args.state.alert = 1
            end
          end
        end
      end
    end
  end

  args.state.security_camera_detection_fields.each do |cfield|
    if args.state.time_seconds <= 10
      if cfield[:direction] == 11
        args.outputs.primitives << cfield
        if cfield.intersect_rect? args.state.player
          args.state.alert = 1
        end
      end
      if cfield[:direction] == 21
        args.outputs.primitives << cfield
        if cfield.intersect_rect? args.state.player
          args.state.alert = 1
        end
      end
    end
    if args.state.time_seconds > 10
      if cfield[:direction] == 12
        args.outputs.primitives << cfield
        if cfield.intersect_rect? args.state.player
          args.state.alert = 1
        end
      end
      if cfield[:direction] == 22
        args.outputs.primitives << cfield
        if cfield.intersect_rect? args.state.player
          args.state.alert = 1
        end
      end
      if args.state.time_seconds == 15
        args.state.time_seconds = 0
      end
    end
  end

  args.state.alert_light.each do |light|
    light[:angle] = args.tick_count % 360
  end

  if args.state.goal.intersect_rect? args.state.player
    args.state.next_scene = :game_win_scene
  end

  args.outputs.background_color = [180, 180, 180]

  if args.state.alert == 1
    args.outputs.labels << [140, 450, "You've been detected! Make a break for the exit!", 10, 255, 255, 255, 255]
  end

  args.outputs.primitives << args.state.player
  args.outputs.primitives << args.state.goal
  args.outputs.primitives << args.state.shelves
  args.outputs.primitives << args.state.boxes
  args.outputs.primitives << args.state.sentry_robots
  args.outputs.primitives << args.state.alert_robots
  args.outputs.primitives << args.state.security_cameras
  if args.state.alert == 1
    args.outputs.primitives << args.state.alert_light
  end
end

def tick_game_over_scene args
  args.outputs.background_color = [0, 0, 0]
  args.outputs.labels << [560, 500, "You got caught!", 10, 255, 255, 255, 255]
  args.outputs.labels << [320, 400, "Press the Enter key to try and escape again.", 10, 255, 255, 255, 255]
  if args.inputs.keyboard.enter
    args.state.next_scene = :game_scene
    args.state.player[:x] = 10
    args.state.player[:y] = 360
    args.state.shelves.clear
    args.state.boxes.clear
    args.state.sentry_robots.clear
    args.state.sentry_robot_detection_fields.clear
    args.state.security_cameras.clear
    args.state.security_camera_detection_fields.clear
    args.state.alert = 0
    args.state.alert_robots.clear
    args.state.alert_robot_detection_fields.clear
    args.state.alert_light.clear
  end
end

def tick_game_win_scene args
  args.outputs.background_color = [0, 0, 0]
  args.outputs.labels << [560, 500, "You escaped!", 10, 255, 255, 255, 255]
  args.outputs.labels << [320, 400, "Press the Enter key to try and escape again.", 10, 255, 255, 255, 255]
  if args.inputs.keyboard.enter
    args.state.next_scene = :game_scene
    args.state.player[:x] = 10
    args.state.player[:y] = 360
    args.state.shelves.clear
    args.state.boxes.clear
    args.state.sentry_robots.clear
    args.state.sentry_robot_detection_fields.clear
    args.state.security_cameras.clear
    args.state.security_camera_detection_fields.clear
    args.state.alert = 0
    args.state.alert_robots.clear
    args.state.alert_robot_detection_fields.clear
    args.state.alert_light.clear
  end
end

def make_shelves
  shelves = []
  shelves += 1.times.map { |n| {x: 750, y: 620, w: 384, h: 48, path: 'sprites/shelf.png'} }
  shelves += 1.times.map { |n| {x: 750, y: 480, w: 384, h: 48, path: 'sprites/shelf.png'} }
  shelves += 1.times.map { |n| {x: 750, y: 340, w: 384, h: 48, path: 'sprites/shelf.png'} }
  shelves += 1.times.map { |n| {x: 750, y: 200, w: 384, h: 48, path: 'sprites/shelf.png'} }
  shelves += 1.times.map { |n| {x: 750, y: 60, w: 384, h: 48, path: 'sprites/shelf.png'} }
  shelves += 1.times.map { |n| {x: 240, y: 620, w: 384, h: 48, path: 'sprites/shelf.png'} }
  shelves += 1.times.map { |n| {x: 240, y: 480, w: 384, h: 48, path: 'sprites/shelf.png'} }
  shelves += 1.times.map { |n| {x: 240, y: 340, w: 384, h: 48, path: 'sprites/shelf.png'} }
  shelves += 1.times.map { |n| {x: 240, y: 200, w: 384, h: 48, path: 'sprites/shelf.png'} }
  shelves += 1.times.map { |n| {x: 240, y: 60, w: 384, h: 48, path: 'sprites/shelf.png'} }
  shelves += 1.times.map { |n| {x: 80, y: 150, w: 48, h: 384, path: 'sprites/shelfvertical.png'} }
  shelves
end

def make_boxes
  boxes = []
  boxes += 1.times.map { |n| {x: 1050, y: 400, w: 64, h: 64, path: 'sprites/box.png'} }
  boxes += 1.times.map { |n| {x: 900, y: 260, w: 64, h: 64, path: 'sprites/box.png'} }
  boxes += 1.times.map { |n| {x: 300, y: 120, w: 64, h: 64, path: 'sprites/box.png'} }
  boxes += 1.times.map { |n| {x: 500, y: 540, w: 64, h: 64, path: 'sprites/box.png'} }
  boxes += 1.times.map { |n| {x: 10, y: 650, w: 64, h: 64, path: 'sprites/box.png'} }
  boxes += 1.times.map { |n| {x: 80, y: 80, w: 64, h: 64, path: 'sprites/box.png'} }
  boxes += 1.times.map { |n| {x: 800, y: 540, w: 64, h: 64, path: 'sprites/box.png'} }
  boxes += 1.times.map { |n| {x: 990, y: 120, w: 64, h: 64, path: 'sprites/box.png'} }
  boxes
end

def make_sentry_robots
  sentry_robots = []
  sentry_robots += 1.times.map { |n| {x: 1160, y: 680, w: 32, h: 32, path: 'sprites/sentryrobot.png', id: 1} }
  sentry_robots += 1.times.map { |n| {x: 190, y: 10, w: 32, h: 32, path: 'sprites/sentryrobot.png', id: 2} }
  sentry_robots += 1.times.map { |n| {x: 700, y: 10, w: 32, h: 32, path: 'sprites/sentryrobot.png', id: 3} }
  sentry_robots += 1.times.map { |n| {x: 640, y: 680, w: 32, h: 32, path: 'sprites/sentryrobot.png', id: 4} }
  sentry_robots
end

def make_sentry_robot_detection_fields
  sentry_robot_detection_fields = []
  sentry_robot_detection_fields += 1.times.map { |n| {x: 1032, y: 680, w: 128, h: 32, path: 'sprites/detectionfieldl.png', id: 1, direction: 11} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 1160, y: 552, w: 32, h: 128, path: 'sprites/detectionfield.png', id: 1, direction: 12} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 1192, y: 680, w: 128, h: 32, path: 'sprites/detectionfieldr.png', id: 1, direction: 13} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 1160, y: 712, w: 32, h: 128, path: 'sprites/detectionfieldu.png', id: 1, direction: 14} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 222, y: 10, w: 128, h: 32, path: 'sprites/detectionfieldr.png', id: 2, direction: 21} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 190, y: 42, w: 32, h: 128, path: 'sprites/detectionfieldu.png', id: 2, direction: 22} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 62, y: 10, w: 128, h: 32, path: 'sprites/detectionfieldl.png', id: 2, direction: 23} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 190, y: -118, w: 32, h: 128, path: 'sprites/detectionfield.png', id: 2, direction: 24} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 572, y: 10, w: 128, h: 32, path: 'sprites/detectionfieldl.png', id: 3, direction: 31} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 700, y: -118, w: 32, h: 128, path: 'sprites/detectionfield.png', id: 3, direction: 32} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 732, y: 10, w: 128, h: 32, path: 'sprites/detectionfieldr.png', id: 3, direction: 33} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 700, y: 42, w: 32, h: 128, path: 'sprites/detectionfieldu.png', id: 3, direction: 34} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 672, y: 680, w: 128, h: 32, path: 'sprites/detectionfieldr.png', id: 4, direction: 41} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 640, y: 712, w: 32, h: 128, path: 'sprites/detectionfieldu.png', id: 4, direction: 42} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 512, y: 680, w: 128, h: 32, path: 'sprites/detectionfieldl.png', id: 4, direction: 43} }
  sentry_robot_detection_fields += 1.times.map { |n| {x: 640, y: 552, w: 32, h: 128, path: 'sprites/detectionfield.png', id: 4, direction: 44} }
  sentry_robot_detection_fields
end

def make_alert_robots
  alert_robots = []
  alert_robots += 1.times.map { |n| {x: -160, y: 10, w: 32, h: 32, path: 'sprites/sentryrobot.png', id: 1} }
  alert_robots += 1.times.map { |n| {x: -640, y: 10, w: 32, h: 32, path: 'sprites/sentryrobot.png', id: 2} }
  alert_robots
end

def make_alert_robot_detection_fields
  alert_robot_detection_fields = []
  alert_robot_detection_fields += 1.times.map { |n| {x: -128, y: 10, w: 128, h: 32, path: 'sprites/detectionfieldr.png', id: 1, direction: 11} }
  alert_robot_detection_fields += 1.times.map { |n| {x: -160, y: 42, w: 32, h: 128, path: 'sprites/detectionfieldu.png', id: 1, direction: 12} }
  alert_robot_detection_fields += 1.times.map { |n| {x: -288, y: 10, w: 128, h: 32, path: 'sprites/detectionfieldl.png', id: 1, direction: 13} }
  alert_robot_detection_fields += 1.times.map { |n| {x: -160, y: -118, w: 32, h: 128, path: 'sprites/detectionfield.png', id: 1, direction: 14} }
  alert_robot_detection_fields += 1.times.map { |n| {x: -608, y: 10, w: 128, h: 32, path: 'sprites/detectionfieldr.png', id: 2, direction: 21} }
  alert_robot_detection_fields += 1.times.map { |n| {x: -640, y: 42, w: 32, h: 128, path: 'sprites/detectionfieldu.png', id: 2, direction: 22} }
  alert_robot_detection_fields += 1.times.map { |n| {x: -768, y: 10, w: 128, h: 32, path: 'sprites/detectionfieldl.png', id: 2, direction: 23} }
  alert_robot_detection_fields += 1.times.map { |n| {x: -640, y: -118, w: 32, h: 128, path: 'sprites/detectionfield.png', id: 2, direction: 24} }
  alert_robot_detection_fields
end

def make_alert_light args
  alert_light = []
  alert_light += 1.times.map { |n| {x: 1144, y: 692, w: 32, h: 8, path: 'sprites/alertlight.png', id: 1, angle: 0, angle_anchor_x: 1, angle_anchor_y: 0.5} }
  alert_light += 1.times.map { |n| {x: 174, y: 22, w: 32, h: 8, path: 'sprites/alertlight.png', id: 2, angle: 0, angle_anchor_x: 1, angle_anchor_y: 0.5} }
  alert_light += 1.times.map { |n| {x: 684, y: 22, w: 32, h: 8, path: 'sprites/alertlight.png', id: 3, angle: 0, angle_anchor_x: 1, angle_anchor_y: 0.5} }
  alert_light += 1.times.map { |n| {x: 624, y: 692, w: 32, h: 8, path: 'sprites/alertlight.png', id: 4, angle: 0, angle_anchor_x: 1, angle_anchor_y: 0.5} }
  alert_light += 1.times.map { |n| {x: -176, y: 22, w: 32, h: 8, path: 'sprites/alertlight.png', id: 5, angle: 0, angle_anchor_x: 1, angle_anchor_y: 0.5} }
  alert_light += 1.times.map { |n| {x: -656, y: 22, w: 32, h: 8, path: 'sprites/alertlight.png', id: 6, angle: 0, angle_anchor_x: 1, angle_anchor_y: 0.5} }
  alert_light
end

def make_security_cameras
  security_cameras = []
  security_cameras += 1.times.map { |n| {x: 1232, y: 672, w: 32, h: 32, path: 'sprites/securitycamera.png', id: 1} }
  security_cameras += 1.times.map { |n| {x: 1232, y: 16, w: 32, h: 32, path: 'sprites/securitycamera.png', id: 2} }
  security_cameras
end

def make_security_camera_detection_fields
  security_camera_detection_fields = []
  security_camera_detection_fields += 1.times.map { |n| {x: 1104, y: 672, w: 128, h: 32, path: 'sprites/detectionfieldl.png', id: 1, direction: 11} }
  security_camera_detection_fields += 1.times.map { |n| {x: 1232, y: 544, w: 32, h: 128, path: 'sprites/detectionfield.png', id: 1, direction: 12} }
  security_camera_detection_fields += 1.times.map { |n| {x: 1104, y: 16, w: 128, h: 32, path: 'sprites/detectionfieldl.png', id: 2, direction: 21} }
  security_camera_detection_fields += 1.times.map { |n| {x: 1232, y: 48, w: 32, h: 128, path: 'sprites/detectionfieldu.png', id: 2, direction: 22} }
  security_camera_detection_fields
end

def debug args
  args.outputs.labels << [10, 50, "Debug:", 3, 255, 255, 255, 255].label
  args.outputs.labels << [10, 80, "Frame: #{(args.state.frames)}", 3, 255, 255, 255, 255].label
  args.outputs.labels << [10, 110, "Timer: #{(args.state.time_seconds)}", 3, 255, 255, 255, 255].label
end