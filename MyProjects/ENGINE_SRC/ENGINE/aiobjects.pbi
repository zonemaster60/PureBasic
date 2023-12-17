;here we use all of the datastructure for objects based on the energy and systemlevel of the GRID

;--worldobjects 

Structure  world_objects
  object_x.i
  object_y.i
  object_ai_path.s
  object_gfx_path.s
  object_gfx_id_frame_left.i[128]  ;
  object_gfx_id_frame_right.i[128] ;
  object_gfx_id_frame_up.i[128]    ;
  object_gfx_id_frame_down.i[128]  ;
  object_gfx_id_frame_anim_default.i[128]
  object_gfx_id_default_frame.i  ;for non anim objects 
  object_gfx_type.s
  object_layer.b
  object_w.f
  object_h.f
  object_use_player_position.b
  object_player_position_offset_y.f
  object_player_position_offset_x.f
  object_stamp_transparency.i
  object_use_child_limit.b
  object_asset_load_pause.i
  object_asset_load_pause_start.i
  object_use_asset_load_pause.b
  object_call_dead_timer.i                      ;use this timer if you want to spawn dead (can use this for player if not moved/no interaction for a given time)
  object_call_dead_timer_total.i
  object_use_call_dead_timer.i
  object_dead_timer_object_ai42.s
  object_call_dead.b
  object_is_reaper.b
  object_rigit_collision_x.f
  object_rigit_collision_y.f
  object_rigit_rotate.f
  object_use_physic_collision.b
  object_did_collision.b
  object_use_physic_loop.b
  object_use_physic_no_collision.b
  object_collision_on_off.b
  object_internal_index.i
  object_collision_on_off_timer_full.i
  object_is_scroll_back_ground.b
  object_use_effect_area.b
  object_scroll_speed_h.f
  object_scroll_scroll_id.i ;holds the scroll objec number!
  object_back_ground_auto_scroll.b
  object_effect_area_h.f
  object_effect_area_w.f
  object_effect_pause.b
  object_use_auto_reposition.b
  object_full_screen.b
  object_collision.b
  object_transparency.f
  object_transparency_back_up.f
  object_use_transparency_back_up.b
  object_is_anim.b  ;global anim flag
  object_is_anim_right.b ;anim flag to check if anim frames for direction present...
  object_is_anim_left.b
  object_is_anim_down.b
  object_is_anim_up.b
  object_is_anim_default.b
  object_is_anim_attack.b
  object_actual_anim_frame_attack.b
  object_last_anim_frame_attack.b
  object_actual_anim_frame_left.b
  object_last_anim_frame_left.b
  object_actual_anim_frame_right.b
  object_last_anim_frame_right.b
  object_actual_anim_frame_up.b
  object_last_anim_frame_up.b
  object_actual_anim_frame_down.b
  object_last_anim_frame_down.b
  object_actual_anim_frame_default.b
  object_last_anim_frame_default.b
  object_default_frame.b ;used for non anim objects
  object_last_move_direction_x.i ;store the last moivedirection to show the correct default animframe
  object_last_move_direction_y.i
  object_anim_timer.l  ;the internal anim timer of the object
  object_anim_frame_time.l  ;here we try to synch the anim with the fps and interpolation value = 1000MS/animframes_per direction
  object_auto_layer.b
  object_use_shadow.b
  object_shadow_intense.l
  object_do_not_show.b ;default is set to 1 = show, script can change value to 0 = hide  , hide removes object from SGFX system
  object_is_active.b   ;default is set to 1 = is active object, script can change value to 0 =deactivate object
  object_is_player.b
  object_is_weapon.b
  object_auto_move_x.f
  object_auto_move_y.f
  object_move_x.f
  object_move_y.f
  object_move_x_max.f
  object_move_y_max.f
  object_jump_velocity.f
  object_jump_velocity_auto.b
  object_kill_value.i    ; a value used to reduce player/object energy/health  used by collision object
  object_move_direction_x.i;stores the actual movedirection for internal handling (#UP,#DOWN,#LEFT,#RIGHT...)
  object_move_direction_y.i
  object_random_rotate.f
  object_is_enemy.b
  object_use_ai.b
  object_internal_name.s
  object_use_random_angle.f  ;for random sprite rotation position at start 
  object_is_on_ground.b  
  object_use_player_direction_x.b
  object_use_player_direction_y.b
  object_no_clear_screen.b
  object_random_spawn_positive_only.b
  object_no_shake_interaction.b
  object_auto_rotate.f
  object_manual_rotate.f
  object_random_transparency.f
  object_shadow_offset_x.f
  object_shadow_offset_y.f
  object_sound_id.i
  object_sound_play_random.i 
  object_sound_on_random_id.i
  object_sound_on_random_path.s
  object_is_global_sound.b
  object_sound_volume.l
  object_play_sound_on_move.b
  object_sound_on_collision_path.s
  object_turn_right_screen_full_spawn.b
  object_debug_if_remove.b
  object_sound_on_collision_id.i
  object_sound_on_rotate_path.s
  object_sound_on_rotate_id.i
  object_sound_on_move_path.s
  object_sound_on_move_id.i
  object_sound_on_create_path.s
  object_sound_on_create_id.i
  object_collision_transparency.f
  object_touch_collision.b
  object_touch_transparency.f
  object_play_sound_on_restore.b 
  object_sound_on_restore_path.s
  object_sound_on_restore_id.i
  object_sound_on_restore_volume.i
  object_sound_on_restore_is_playing.b
  ;object_is_in_area.b   ;for objects only handled if visible on screen/in screen area
  object_is_in_area_shadow.b ;use this if you want more performance (shadows will be used if object inner shadowarea)
  object_collision_pixel.b
  object_collision_tractor_object.b  ;sets move direction of collisions object to move directions of tractor
  object_autotransport_x.f
  object_autotransport_y.f
  object_is_auto_scroll_x.f
  object_is_auto_scroll_y.f
  object_alternative_gfx_default_ai42.s ;holds the id for alternative objects gfx (will be instant loaded)
  object_use_random_alternative_gfx.l ;if >0 a random number  (0 to x) will be genrated, if number is valid we get an random "loot"/alternative object, if not valid we get the default alternative
  object_alternative_random_gfx_ai0.s
  object_alternative_random_gfx_ai1.s
  object_alternative_random_gfx_ai2.s
  object_alternative_random_gfx_ai3.s
  object_alternative_random_gfx_ai4.s
  object_alternative_random_gfx_ai5.s
  object_alternative_random_gfx_ai6.s
  object_change_on_collision.b ;trigger  if active alternative gfx will be loaded and shown..., source gfx will be set to inactive and not shown
  object_blink_timer.i         ;if <> 0 object will be schown in the given intervall
  object_blink_start.i         ; holds the timespace for blinking
  object_use_blink_timer.b
  object_blink_object_show.b   ; (if true object is shown, its used as flip flop value)
  object_life_time.l
  object_end_of_life_time.l
  object_change_on_random.l
  object_can_change.b
  object_stream_gfx_loaded.b
;if this flag is set a counter will increase so the player has to do.... x of actions (collect some keys...) if all done the map opens a gate to go to next mapS
  object_do_not_save.b   ;used for snapshots of the game, we only save objects, which are in game and  valid for furhter gameplay
  object_use_fade.b        ;#true/#false
  object_does_attack.i       ;if random(value)=1 attack!
  object_remove_gfx.l  ;used for the streamsystem to free memory, if areas  not visited or left a long time  (30 sec)
  object_do_not_stream.b
  object_no_siluette.b
  object_random_anim_start.l
  object_hp.f
  object_hp_max.f
  object_level.i
  object_attack.i
  object_use_in_front_transparency.b
  object_in_front_transparency.i
  object_defence.i
  object_change_on_fade_out.b
  object_emit_stop_on_collision.b
  object_ingame_name.s
  object_play_sound_on_emit.b
  object_sound_on_emit_volume.i
  object_sound_on_emit_path.s
  object_emit_sound_id.i
  object_sound_on_change_id.i
  object_sound_on_change_volume.i
  object_sound_on_change_path.s
  object_play_sound_on_change.b
  object_create_child.b  ;number 
  object_child0_gfx_ai42.s
  object_child1_gfx_ai42.s
  object_child2_gfx_ai42.s
  object_child3_gfx_ai42.s
  object_child4_gfx_ai42.s
  object_child5_gfx_ai42.s
  object_child6_gfx_ai42.s
  object_child7_gfx_ai42.s
  object_child8_gfx_ai42.s
  object_child9_gfx_ai42.s
  object_deactivate_tractor_if_left_border.b
  object_create_child_random.l
  object_remove_from_list.b
  object_child_gfx_ai_path.s
  object_random_size_on_start.f
  object_weapon_create_paths_ai42.s
  object_weapon_timeout.l
  object_ontrigger_move_x.f
  object_ontrigger_move_y.f
  object_ontrigger_activate.b
  object_is_trigger.b
  object_use_default_direction.s
  object_area_no_limit.b       ;used for object which ccan be active  out of view (like  moving coins, specials, .....effects)
  object_NPC_text_path.s
  object_NPC_show_text_on_collision.b
  object_NPC_internal_name.s
  object_NPC_text_pic_path.s
  object_NPC_talk_area_h.f
  object_NPC_talk_area_w.f
  object_NPC_use_talk_area.b
  object_NPC_is_talking.b
  object_fade_out_per_tick.f
  object_use_indexer.b  ;now we use this value #true or #false to setup objects for indexer use
  object_use_random_shadow_color.l
  object_shadow_color.l
  ;-------------------------------------------------------------------------------------------------------------for the "realtime" map creator module
  object_procedural_new_random_object_max.b  ;number like create child, uses create child routines (clone)
  object_procedural_new_object_random_seed.l ;random number (if random = 1 , we do something)
  
  object_boss_music_volume.i
  object_boss_music_path.s
  object_boss_music_id.i
  object_boss_music_is_playing.b
  object_force_own_layer.b  ;used to place object on its autolayer (workaround for some false positioning, and for defined positioning) if<>0 it will be usd
  object_child_total.i
  object_child_total_counter.b
  object_random_xp.i ;used for the x points to level up the axe and the char
  object_health_bar_path.s
  object_health_bar_size_w.f
  object_health_bar_size_h.f
  object_health_bar_active.b
  object_health_bar_factor.f
  object_health_bar_actual_hp.f
  object_health_bar_maximum_hp.f
  object_health_bar_id.i
  object_health_bar_update.b
  object_health_bar_back_id.i
  object_health_bar_back_path.s
  object_set_child_direction.b
  object_use_parent_direction.b
  object_random_hide_away.i
  object_create_no_child_if_hide_away.b
  object_restore_health_if_hide_away.f
  object_random_hide_away_sound.s
  object_random_hide_away_sound_volume.i
  object_random_hide_away_sound_id.i
  object_hide_away_layer.b
  object_actual_layer_back_up.b
  object_collision_back_up.b  ;store the default collision (#true/#false)
  object_hide_away_status.b
  object_hide_away_time_out.l
  object_hide_away_pause.l
  object_hide_away_pause_time.l
  object_remove_with_boss.b
  object_is_boss.b
  object_hide_away_time.l
  object_ignore_weapon_on_hide.b
  object_no_collision_on_hide.b
  object_follow_player.b
  object_is_key_for_gate.s  ;the key to the door (if activated, system search for object with door name, and deactivates it)
  object_gate_open.b        ;#true if gatesystem  found valid key and gate
  object_use_random_pause.b
  object_need_gold.l
  object_gold_value.l
  object_price_tag_id.i
  object_price_tag_height.f
  object_price_tag_width.f
  object_price_tag_path.s
  object_price_tag_is_active.b
  object_inventory_object_path.s
  object_spawn_offset_x.f
  object_spawn_offset_y.f
  object_is_heal_potion.i
  object_play_sound_on_rotate.b
  object_sound_on_rotate_volume.i
  object_is_amor_up_potion.l
  object_danger_gfx_path.s
  object_danger_gfx_id.i
  object_danger_gfx_is_active.b
  object_use_inventory_object.s;just to save some checking
  object_change_on_inventory_object.b  ;use this (value =1 for true) to change object after inventoryobject is used, we use the "object_alternative_gfx_ai.s" value as target 
  object_inventory_quest_object_remove_after_use.b ;for questobjects, are they for one shot use or permanent? #true =remove from inventory!
  object_inventory_name.s
  object_danger_gfx_hight.f
  object_danger_gfx_width.f
  object_night_mode.b
  object_layer_add.l  ;we can change the layer +/-
  object_open_gate_on_death.s
  object_action_on_internal_name.b
  object_show_boss_bar.b
  object_death_action_ai42.s  ;here we storeand call the alternative file for the death sequence
  object_swing_rotate_angle.i  ;positive values supported only
  object_swing_rotate_step.f
  object_swing_rotate_start_angle.f
  object_swing_rotate_step_direction.b
  object_swing_rotate_actual_angle.f
  object_fixed_xp.i
  object_stream_life_time.l  ; release object after out of view and counter....  ;we use a fixed time for 10secs for developement.
  object_use_locale.b           ;language sensitive action
  object_anim_speed.l           ; 
  object_sound_is_boss.b        ;use it for some dramtaic sound effects (eg: just the boss sound, no other...its a cool situation)
 ; object_do_not_remove.b        ;for some special objects like boss enemies, so the do not reload afer day/night change
  object_is_in_gfx_area.b
  object_is_defect.b   ;something went wrong with the gfx/data of the object, try to remove this or just jump over it
  object_do_change.b ;use this for the object alternative gfx process
  object_random_size_factor.f ;scale the object randomly per tick#
  object_random_size_change.l ;random value triggrer for random size factor start
  object_target_on_player.b   ;for bullets or other player following stuff (instead of player following object, this object does not update direction)
  object_collision_static_id.i;use this for a reduced collision system : objects with same ID do not collison (enemies do not collision with enemies) saves much cpu cycles
  object_collision_static_id_backup.i
  object_collision_static_alternative_id.i
  object_internal_name_alternative.s  ;can be used for object change based on name : if #TELEPORT does teleport, you can set alternative to #TELEPORT and internal name to for example #TELEPORT_OFF, if you change #TELEPORT_OFF to #TELEPORT the engine will handle the object as #TELEPORT
  object_activated_by_object.b 
  object_activate_other_on_creation.b
    
  object_night_ai42_file.s            ;define a specific "night" ai42.file , this key is not used, implementation is not final
  object_fade_in_on_creation.b
  object_fade_in_on_creation_step.f
  object_transparency_target.f
  object_keep_on_change.b
  object_create_child_sound.s
  object_create_child_sound_volume.l
  object_create_child_sound_id.i
  object_change_on_dead.b
  object_change_on_life_time_is_over.b
  object_is_map_ground.b
  object_use_map_ground.b
  object_sound_path.s
  object_spawn_random_x.f
  object_spawn_random_y.f
  object_fade_bounce.f
  object_fade_bounce_add.b
  object_sound_play_on_rotate.b
  object_no_weapon_interaction.b
  object_weapon_remove_after_hit.b
  object_sound_on_activate_path.s
  object_play_sound_on_activate.b
  object_sound_on_activate_id.i
  object_no_enemy_action.b
  
  object_use_fight_effect.b
  object_fight_effect_gfx_path.s
  object_fight_effect_id.i
  object_is_in_fight.b
  object_fight_effect_h.f
  object_fight_effect_w.f
  
  ;for light effects : not implemented , working on
  object_is_light.b

  object_light_r.l
  object_light_g.l
  object_light_b.l
  object_light_r_start.l
  object_light_g_start.l
  object_light_b_start.l
  object_night_r.l
  object_night_g.l
  object_night_b.l
  object_night_r_start.l
  object_night_g_start.l
  object_night_b_start.l
  object_night_intense.l
  object_night_color_RGB.l
  object_light_color_RGB.l
  object_light_color_r.l
  object_light_color_g.l
  object_light_color_b.l
  ;--------------------
  
  ;global day (night illumination)
  object_use_day_night_change.b
   object_light_intensity.f
   object_light_size_factor.f
   object_ready_to_change.b
   object_remove_after_collison.b
   object_remove_after_change.b
   object_inactive_after_change.b
   object_inactive_after_collision.b
   object_inactive_after_timer.b
   object_no_collision_after_collision.b
   object_do_not_save_after_change.b
   object_remove_after_fade_out.b
   object_remove_after_timer.b
   object_use_gravity.b
   object_move_direction_backup.b
   object_jump_size.f
   object_jump_size_actual.f
   object_jump_step.f
   object_is_jumping.b
   object_can_jump.b
   object_is_falling.b
   object_can_move_in.b
   object_save_map_on_collision.b
   object_reactivation_timer_ms.l
   object_reactivation_time.l
   object_is_loot.b
   object_allert_overide_by_player_attack.b
   object_allert_overide_timer.l
   object_allert_overide_timer_stop.l
   object_sound_on_move_length_ms.l
   object_sound_on_move_ready_ms.l
   object_sound_on_random_length_ms.l
   object_sound_on_random_ready_ms.l
   object_first_start.b
   object_sound_on_rotate_length_ms.l
   object_sound_on_rotate_ready_ms.l
   object_time_stamp.l                  ;use it or not
   object_set_night.b
   object_set_day.b
   object_is_NESW.b
   object_xp_on_remove.l
   object_life_timer_on_collision.l
   object_life_timer_on_activation.l
   object_random_rotate_on_activation.l
   object_collision_get_dynamic_id.b
   ;some openworld enemy activations: we can tell enemies to be active/allert if player is near, so action starts if player is near, player can not kill / hit enemy if action is not started
   object_allert_on_player.b
   object_allert_stay.b
   object_do_create_child.b  
   object_is_child.b
   object_play_sound_on_create_child.b
   object_play_sound_on_create.b
   object_use_spawn_border_offset.b
   object_show_hp_bar.b
   object_alternative_create_sound_path.s
   object_alternative_create_sound_id.i
   object_play_sound_on_collision.b
   object_angle_on_creation.f ;stores the angle (0...360) at creation , usefull for random angle
   object_boss_music_mode.b   ;if true no fight music is started.level music is played anyway
   object_stop_all_music.b    ;set this true if you want to stop all music after fight/if object is killed...
   object_hp_factor.l         ;use this to increase the difficulti (hp  value of enemy = axe power * hp factor
   object_shadow_use_perspective.b
   object_shadow_gfx_path.s
   object_shadow_gfx_id.i
   object_shadow_w.f
   object_shadow_h.f
   object_resize_per_tick.f
   object_remove_after_full_resize.b
   object_remove_if_out_of_area.b
   object_glass_effect_grab_size.f
   object_glass_effect_intensity.i
   object_glass_effect_offset_x.f
   object_glass_effect_offset_y.f
   object_use_glass_effect.b
   object_glass_effect_gfx_id.i
   object_restore_health_if_out_of_area.f
   object_restore_health_if_not_allert.f
   object_slippery_mode.b  ;make it slippery? player will have movement in last direction, without control, until collision with other object happen
   object_is_arena_object.b
   object_play_sound_on_treasure.b
   object_use_attack_direction.b
   object_change_emitter.b
   object_change_emitter_with_id.i
   object_emitter_id.i
   object_switch_map_path.s
   object_switch_map.b
   object_change_emitter_new_path.s
   object_sound_on_treasure_found_path.s
   object_sound_on_treasure_found_id.i
   object_allert_on_treasure.b
   object_activate_on_inventory.s
   object_spawn_at_player_if_out_of_area.b
   object_respawn_timer.l
   object_respawn_timer_target.l
   object_collision_ignore_player.b
   object_is_attraction.b
   object_attraction_pick_up.b
   object_go_for_attraction.b
   object_stop_if_attraction.b
   object_is_global_light.b
   object_global_light_red.i
   object_global_light_green.i
   object_global_light_blue.i
   object_global_light_intensity.i
   object_resize_pixel_x.f
   object_resize_pixel_y.f
   object_resize_per_percent_x.f
   object_resize_per_percent_y.f
   object_move_on_collision_x.f
   object_move_on_collision_y.f
   object_do_not_save_after_collision.b
   object_fade_out_on_collision.f
   object_change_move_after_collision.b
   object_activate_on_companion.b
   object_procedural_object.s
   object_set_night_intensity.l
   object_set_day_intensity.l
   object_emit_on_move.b
   object_emit_on_move_ai42.s
   object_emit_on_move_random.l
   object_set_day_night_change_ai42.s
   object_action_status_x.l  ;moving, waiting, stand, look, open chest, walk, used for some effects with action situation
   object_action_status_y.l 
   object_NPC_switch_map_on_talk.b  ;we can switch maps after talk to NPC (story situations)
   object_NPC_switch_map_on_talk_file.s
   object_set_emitter_day_ai42.s
   object_set_emitter_night_ai42.s
   object_set_day_night_emitter_random.l
   object_activate_on_night.b
   object_activate_on_day.b
   object_deactivate_on_night.b
   object_deactivate_on_day.b
   object_origin_position_x.f
   object_origin_position_y.f
   object_effect_on_player_collision.b
   object_remove_after_effect_on_player.b
   object_use_effect_on_percent_value.f
   object_change_value_per_percent.f
   object_remove_after_dead.b
   object_remove_on_day.b
   object_remove_on_night.b
   object_remove_after_last_anim_frame.b
   object_create_on_level_up.b
   object_child_on_level_up_ai42.s
   object_deactivate_use_alternative_gfx.b
   object_change_on_last_frame.b
   object_use_teleport_effect.b
   object_teleport_gfx_path.s
   object_hit_blink_timer_ms.l
   object_hit_blink_time_ms.l
   object_use_spawn_offset.b
   object_NPC_map_timer_active_on_talk.l
   object_add_timer_to_map.l
   object_play_sound_on_talk.b
   object_sound_on_talk_path.s
   object_sound_on_talk_id.i  
   object_sound_on_talk_volume.i
   object_anim_no_auto_align.b
   object_use_virtual_buffer.b
   object_use_make_move_timer.b
   object_move_time.i
   object_random_make_move_timer.i
   object_make_move_timer.i
   object_move_x_only.b
   object_move_y_only.b
   object_use_dynamic_id.b
   object_use_static_id.l
   object_energy.l
   object_shake_world.b   
   object_use_isometric.b
   object_virtual_y.i ;use this for non iso objects! like floors! this virtual y  will be 0 as default!
   object_use_energy_status.b
   object_use_position_on_raster.b
   object_use_timed_action.b
   object_own_color_intensity.i
   object_color_RGB.i
   object_use_own_color.b
   object_color_red.i
   object_color_green.i
   object_color_blue.i
   object_use_random_start_direction.b
  object_use_random_start_direction_x.b
  object_use_random_start_direction_y.b
  object_sound_on_jump_id.i
  object_start_angle.f
  object_speed_change_x.f
  object_speed_change_y.f
  object_use_speed_change.b
   object_play_sound_on_jump.b
   object_sound_on_jump_paths.s
   object_sound_on_jump_volume.l
   object_random_change_direction_x.l
   object_random_change_direction_y.l
   object_change_direction_on_random.b
   object_use_own_trigger_zone.b
   object_own_trigger_zone_w.f
   object_own_trigger_zone_h.f
   object_area_loop_horizont.b
   object_area_loop_vertical.b
   object_show_coordinates.b  ;for debugging
   object_reset_position_on_timer.b
   object_reset_position_time_ms.l
   object_reset_position_time_counter.l
   object_emitter_max_objects.l
   object_emitter_use_max_objects.b
   object_emitter_actual_object.l
   object_emitter_max_objects_random.l
   object_emit_object_ai42_default.s
   object_use_attack_anim.b
   object_is_attacking.b
   object_last_move_direction_x_before_attacking.l
   object_last_move_direction_y_before_attacking.l
   object_turn_on_left_screen.b
   object_use_position_back_up.b
   object_check_if_player_on_top.b
   object_anim_start_on_collison.b
   object_no_interaction_on_enemy.b
   object_emit_on_timer.b
   object_emit_timer.i
   object_emit_timer_actual.i
   object_collision_flip_flop.b
   object_backup_size.b
   object_backup_size_w.f
   object_backup_size_h.f
   object_sound_is_playing.b
   object_play_sound_once.b
   object_activate_map_scroll.b
   object_deactivate_map_scroll.b
   object_do_not_save_after_inactive.b
   object_use_status_controller.b
   object_stop_jump_counter.i
   object_jump_counter.i
   object_static_move.b
   object_use_stamp.b
   object_stamp_gfx_id.i
   object_stamp_gfx_width.f
   object_stamp_gfx_height.f
   object_stamp_buffer_path.s
   object_life_time_pixel_x.f
   object_life_time_pixel_y.f
   object_use_start_direction.b
   object_default_start_direction.s
   object_life_time_pixel_count_x.f
   object_life_time_pixel_count_y.f
   object_use_life_time_per_pixel.b
   object_reset_position_on_pixel_count.b
   object_remove_after_pixel_count.b
   object_anim_loop.b
   object_anim_loop_direction.b
   object_sound_on_move_volume.i
   object_sound_on_create_volume.i
   object_sound_on_random_volume.i
   object_play_sound_on_random.b
   object_stop_after_pixel_count.b
   object_activate_global_flash.b
   object_random_life_time.i
   object_random_transparency_on_start.f
   object_use_random_transparency_on_start.b
   object_change_after_pixel_count.b
   object_anim_move_direction_x.i
   object_anim_move_direction_y.i
   object_stream_sound_on_create.b
   object_stream_sound_on_move.b
   object_change_direction_x_on_max.b
   object_change_direction_y_on_max.b
   object_no_flash_interaction.b
   object_sound_on_collision_volume.i
   object_gfx_set_w_h.b
   object_gfx_h.f
   object_gfx_w.f
   object_no_global_light_interaction.b
   object_rotate.i
   object_is_global_light_on_collision.b
   object_use_random_start_speed_x.b
   object_use_random_start_speed_y.b
   object_random_start_speed_x.i
   object_random_start_speed_y.i
   object_reset_position_on_fade_out.b
   object_use_random_color_RGB.b
   object_show_hit_effect.b
   object_hit_effect_path.s
   object_use_random_jump.b
   object_jump_start_random.i
   object_is_ready_to_jump.b
   object_is_boss_guard.b
   object_info_text.s
   object_sound_on_activate_volume.i
   object_play_sound_on_allert.b
   object_sound_on_allert_path.s
   object_sound_on_allert_id.i
   object_sound_on_allert_volume.i
   object_set_player_gravity_off.b
   object_ignore_one_key.b
   object_use_enemy_maximum.b
   object_enemy_maximum.i
   object_is_transporter.b
   object_stop_move_after_collision.b
   object_turn_on_screen_center.b
   object_follow_player_after_timer.b
   object_follow_player_timer.i
   object_follow_player_timer_actual.i
   object_follow_player_on_timer.i
   object_spawn_offset_parent_center.b
   object_parent_width.f
   object_parent_height.f
   object_rotate_left.f
   object_rotate_right.f
   object_use_rotate_direction.b
   object_use_swing_rotate.b
   object_is_in_stream_area.b
   object_stop_if_guard_on_screen.b
   object_NPC_remove_after_talk.b
   object_emitter_pause_if_idle.b
   object_idle.b
   object_remove_with_guard.b
   object_emitter_pause_if_spawn.b
   object_emit_stop_if_guard_on_screen.b
   object_is_spawn_destination.b
   object_use_spawn_destination.b
   object_did_spawn.b
   object_random_spawn_destination.i
   object_use_random_layer.b
   object_random_layer.i
   object_use_creation_counter.b
   object_use_global_spawn.b
   object_use_status_controller_parent.b
   object_child_name.s
   object_guarded.b
   object_move_flappy_mode.b
   object_use_air_time_kill.b
   object_save_map_on_creation.b
   object_hit_box_x.f
   object_hit_box_y.f
   object_hit_box_w.f
   object_hit_box_h.f
   object_hit_box_gfx_id.i
   object_use_global_effect.b
   object_global_effect_ai42.s
   object_glass_effect_grab_x.f
   object_glass_effect_grab_y.f
   object_stop_move_right_border.b
   object_turn_on_right_border.b
   object_emit_on_jump.b
   object_emit_object_jump_ai42.s
   object_emit_jump_value.i
   object_use_horizontal_velocity.b
   object_velocity_horizontal.f
   object_velocity_vertical.f
   object_use_vertical_velocity.b
   object_horizontal_direction_change.b
   object_vertical_direction_change.b
   object_overide_static_move.b
   object_no_horizontal_move_if_falling.b
   object_no_horizontal_move_active.b
   object_no_child_if_move_down.b
   object_no_gravity_after_collision.b
   object_has_changed_on_collsion.b
   object_use_teleport_on_max_x.b
   object_save_map_on_remove.b
   object_set_fade_out_on_ai.b
   object_activate_fade_out_on_ai.b
   object_music_global_start.b
   object_anim_stop_after_last_frame.b
   object_keep_move_direction.b
   object_emit_jump_object_max.i
   object_emit_jump_counter.i
   object_stop_scroll_after_allert.b
   object_no_fight.b
   object_anim_full_path_for_secu_sys_left.s[127]
   object_anim_full_path_for_secu_sys_right.s[127]
   object_anim_full_path_for_secu_sys_up.s[127]
   object_anim_full_path_for_secu_sys_down.s[127]
   object_anim_full_path_for_secu_sys_default.s[127]
   EndStructure

Structure npc_text
  text_text.s[96]
  text_last_line.i
  text_pos_x.f
  text_pos_y.f
  text_show_line.f
  text_offset_x.f
  text_offset_y.f
  text_last_text_id.b  ;for the random text mode (values 0.....127)
  npc_conversation_switch_map.b
  npc_conversation_switch_map_file.s
  npc_conversation_activate_map_timer_time.i
  npc_text_pop_up_sound_id.i
  npc_text_pop_up_sound_path.s
  npc_text_pop_up_sound_volume.i
  npc_button_B.i
  npc_button_A.i
  npc_button_X.i
  npc_button_Y.i
  npc_button_B_path.s
  npc_remove_after_talk.b
  npc_speach_file_path.s
  npc_speach_output_id.i
  npc_speach_output_file_type.s
  npc_speach_set_global_volume.i  ;sets the global/back sound to new volume (more quiet), so the spoken text can be heared optimal!
 EndStructure

 Structure npc_confy
   confy_id.i
   confy_x.f
   confy_y.f
   confy_w.f
   confy_h.f
   confy_show.b   
   confy_path.s
 EndStructure
 
 Structure auto_switch_map
   name.s
 EndStructure
 
Structure maps
  _name.s
  _respawn.b
EndStructure

;----player objects

Structure player_statistics
  player_move_direction_x.l
  player_move_direction_y.l
  player_core_path.s
  player_quest_progress.l
  player_level_done.b
  player_sound_on_death.s
  player_sound_on_death_id.i
  player_sound_on_level_up.s
  player_sound_on_level_up_id.i
  player_sound_on_found_all_quest_objects.s
  player_sound_on_found_all_quest_objects_id.i
  player_quest_size.i  ;holds the number of action to  solve the quest/map
  player_level.f
  player_level_magic.f
  player_level_fight.f
  player_level_defence.f
  player_level_defence_timer.l
  player_level_defence_timer_start.l
  player_level_defence_max.f
  player_no_random_fight_value.i  ;if result =0 then random fight is active., higher level of random fight will cause in less random fight   
  player_in_fight.b               ;if player in fight this will be set #true
  player_timer_after_fight.l      ;timer is set at fight, and count down after fight. if 0 and no collision with fight enemy, game save is activated, otherwhise the game will not save progress
  player_sound_on_fight.s
  player_sound_on_fight_id.i
  player_sound_on_win_id.i
  player_sound_on_item_pic_up_id.i
  player_sound_on_item_pic_up_paths.s
  player_sound_on_win.s
  player_sound_on_shield_power_up_id.i
  player_sound_on_shield_power_up_paths.s
  player_sound_on_shield_done.b
  player_interface_object_name.s
  player_show_interface.b
  player_health_bar_symbol_path.s
  player_health_bar_symbol_id.i
  player_health_bar_symbol_width.f
  player_health_bar_symbol_height.f
  player_health_bar_symbol_is_valid.b
  player_health_max.f
  player_health_actual.f
  player_health_bar_size_factor.f
  player_health_bar_width.f
  player_health_bar_height.f
  player_health_bar_path.s
  player_health_bar_id.i
  player_health_bar_pos_x.f
  player_health_bar_pos_y.f
  player_health_bar_show.b
  player_health_bar_transparency.f
  player_health_bar_back_transparency.f
  player_health_bar_back_path.s
  player_health_bar_back_offset_x.f
  player_health_bar_back_offset_y.f
  player_health_bar_back_id.i
  player_health_bar_back_height.f
  player_quest_bar_back_id.i
  player_quest_bar_id.i
  player_quest_bar_pos_x.f
  player_quest_bar_pos_y.f
  player_quest_bar_show.b
  player_quest_bar_width.f
  player_quest_bar_height.f
  player_quest_bar_actual.f
  player_quest_bar_path.s
  player_quest_bar_back_path.s
  player_quest_bar_size_factor.f
  player_quest_bar_max.f
  player_quest_bar_back_transparency.f
  player_quest_bar_transparency.f
  
  ;--- the player xp bar....
  player_xp_next_level.i ; xp level to go for next level, xp next level will be set: player_xp_next_level * (player_level.l+(player_level.l/100)); for develope it hardcoded , use script for final product
  player_xp_max.f
  player_xp_actual.f
  player_xp_bar_size_factor.f
  player_xp_bar_width.f
  player_xp_bar_height.f
  player_xp_bar_path.s
  player_xp_bar_id.i
  player_xp_bar_pos_x.f
  player_xp_bar_pos_y.f
  player_xp_bar_show.b
  player_xp_bar_transparency.f
  player_xp_bar_back_transparency.f
  player_xp_bar_back_path.s
  player_xp_bar_back_offset_x.f
  player_xp_bar_back_offset_y.f
  player_xp_bar_back_id.i
  player_xp_bar_back_height.f
  player_xp_bar_back_width.f
  player_xp_count_to_zero.f  ;use this for xp fill effect
  player_info_font_name.s    ;used for some realtime inserts (like: can not save because in fight)
  player_info_font_size.f
  
  ;---player show defence:
  player_defence_object_path.s
  player_defence_object_id.i
  player_defence_object_show.b
  player_defence_object_sound_path.s
  player_defence_object_sound_id.i
  player_defence_object_is_valid.b
  player_defence_object_show_time.l
  player_defence_object_show_end_time.l
  player_defence_bar_path.s
  player_defence_bar_id.i
  player_defence_bar_x.f
  player_defence_bar_y.f
  player_defence_bar_transparency.f
  player_defence_bar_show.b
  player_defence_broken_sound_id.l
  player_defence_bar_width.f
  player_defence_bar_height.f
  player_defence_bar_factor.f
  player_hit_enemy_sound_id.i
  player_hit_by_enemy_sound_id.i
  player_ready_for_new_world.b
  player_ready_for_new_world_value.l  ;a simple, single value we use to check if hp/level/axe.... are ready for new worlds (not maps!!!) if value is given we can move on to swampland
  player_sound_on_fight_volume.l
  ;---inventory:
  player_refresh_xp_gfx.b
  player_refesh_health_gfx.b
  player_last_xp.l
  player_last_health.l
  player_last_defence.l
  player_inventory_max.b
  player_inventory_pos_x.f
  player_inventory_pos_y.f
  player_inventory_gfx_size_w.f
  player_inventory_gfx_size_h.f
  player_inventory_back_banner_path.s
  player_invnetory_back_banner_x.f
  player_inventory_back_banner_y.f
  player_inventory_back_banner_id.i
  player_inventory_show.b
  player_inventory_base_pos_x.f
  player_inventory_base_pos_y.f
  player_inventory_item_y_offset.f
  player_inventory_item_x_offset.f
  player_gold_text_offset_y.f
  player_gold_text_offset_x.f
  player_inventory_text_offset_x.f
  player_inventory_text_offset_y.f
  player_inventory_raster_x.l
  player_inventory_raster_y.l
  player_inventory_max_objects_per_line.l
  player_torch_light_id.i
  player_torch_light_path.s
  player_torch_light_x.f
  player_torch_light_y.f
  player_torch_light_is_active.b
  player_torch_light_width.f
  player_torch_light_height.f
  player_torch_light_transparency.f
  player_torch_light_flicker.l
  player_fight_symbol_paths.s
  player_fight_symbol_id.i
  player_fight_symbol_x.f
  player_fight_symbol_y.f
  player_fight_symbol_width.f
  player_fight_symbol_height.f
  player_fight_symbol_is_active.b
  player_fight_symbol_transparency.f
  player_spawn_plate_x.f
  player_spawn_plate_y.f
  player_spawn_map_offset_x.f
  player_spawn_map_offset_y.f
  player_spawn_teleport_sound_id.i
  player_spawn_teleport_sound_path.s
  player_map_name_offset_x.f
  player_map_name_offset_y.f
  player_difficulty_scale.f
  player_difficulty_scale_factor.f
  player_weapon_axe.b  ;if <>0 axe can be used /is equipped
  player_weapon_shield.b
  player_debug_weapon_active.b
  player_pos_x.f
  player_pos_y.f
  player_object_height.f
  player_object_widht.f
  player_gui_timer.i
  player_gold.i
  player_GUI_gold_pos_x.f
  player_GUI_gold_pos_y.f
  player_GUI_gold_id.i
  player_GUI_gold_path.s
  player_GUI_gold_width.f
  player_GUI_gold_height.f
  player_inventory_show_full.b
  player_last_direction.b
  player_last_save_position_x.f
  player_last_save_position_y.f
  player_axe_speed_max.l
  player_axe_speed.l
  player_use_torch.b
  player_interaction_pause.i  ;wait between actions
  player_next_map_spawn_compass.b  ;uses the new spawn compassystem if a NESW object is touched. NOT supported by this engine build
  player_compass_is_valid.b        ;dummy 
  player_do_not_play_fight_music.b ;in some cases it may usefull not to play the the fight music
  player_last_move_direction_x.l
  player_last_move_direction_y.l
  player_arena_enemies.l  ;stores the ammount of arena enemies (object_is_arena_object)
  ;---companion section
  player_has_companion.b
  player_companion_go_for_attraction_position_x.f
  player_companion_go_for_attraction_position_y.f
  player_companion_hunt_for_attraction.b
  player_call_companion.b
  player_companion_file.s
  player_hide_companion.b  ;if player is in fight we hide companion, so companion does not infect fight
  player_gold_in_chamber.l
  player_name.s  ;use this to name the player, user can rename player on start of game for more personal setup
  player_is_level_up.b
  player_fight_timer.l
  player_fight_music_is_playing.b
  player_hit_enemy_sound_volume.l
  player_axe_speed_base.l
  player_game_mode.l
  player_on_ground.b
  player_moves_world.b
  player_is_ready_to_jump.b
  player_throw_axe.b
  player_show_xp_bar.b
  player_does_climp.b
  player_last_attack_direction.l
  player_critical_hit_gfx_id.i
  player_level_up_gfx_id.i
  player_level_up_gfx_path.s
  player_show_info_as_gfx.b
  player_critical_hit_gfx_path.s
  player_health_symbol_pos_x.f
  player_health_symbol_pos_y.f
  player_health_symbol_offset_x.f
  player_health_symbol_offset_y.f
  player_health_symbol_max_symbols.b
  player_health_symbol_max_symbols_default.i ;backup to reset max symbols if game new start if engine is active
  player_health_symbol_actual_symbol.b
  player_health_symbol_gfx_id.i  ;126=dummy maximum of symbols, we will use maybe 3 symbols (3x heart)
  player_health_symbol_show.b
  player_health_symbol_location.s
  player_health_symbol_transparency.f
  player_pos_back_up_x.f
  player_pos_back_up_y.f
  player_e_world_offset_x_back_up.f
  player_e_world_offset_y_back_up.f
  player_torch_light_big_id.i
  player_torch_light_big_x.f
  player_torch_light_big_y.f
  player_torch_light_big_width.f
  player_torch_light_big_height.f
  player_torch_light_big_transparency.f
  player_torch_light_big_path.s
  player_move_y.f
  player_ignore_gravity.b
  player_is_ready_to_fall.b ;use this for some platforms (move down threw the platform)
  *player_list_object_id    ;to switch fast between actual object and player object
  player_in_air_time_kill.i  ;use this if jumpnrun mode for player char falling threw map... (falling but no obstacles kill player)
  player_in_air_timer.i
  player_effect_status_on.b
  player_effect_status_type.s  
  player_key_pressed.b
EndStructure

;---bossbar
Structure boss_bar
  boss_bar_x.f
  boss_bar_y.f
  boss_bar_front_gfx_id.i
  boss_bar_back_gfx_id.i
  boss_bar_size_w.f
  boss_bar_size_h.f
  boss_bar_is_true.b
  boss_bar_back_path.s
  boss_bar_front_path.s
  boss_bar_cover_path.s
  boss_bar_cover_gfx_id.i
  boss_bar_cover_transparency.i
  boss_bar_boss_name_x_offset.f
  boss_bar_boss_name_y_offset.f
  boss_bar_size_factor.f
  boss_bar_is_valid.b
  boss_bar_is_active.b
  boss_bar_actual_health.i
  boss_bar_maximum_health.i
  boss_bar_update.b
  boss_bar_danger_gfx_id.i
  boss_bar_danger_gfx_path.s
  boss_bar_danger_gfx_is_valid.b
  boss_bar_danger_x.f
  boss_bar_danger_y.f
EndStructure

;--buttoneffects
Structure button_sound
  button_sound_id.i
  button_sound_active.b
  button_sound_path.s
EndStructure

;---helpvars worldobject
Structure e_world_object
  e_world_object_1_hp.i
  e_world_object_1_attack.i
  e_world_object_2_hp.i
  e_world_object_2_attack.i
EndStructure

;---worldtime
Structure e_world_time  ;ingame world time
  e_world_time_second.b
  e_world_time_minute.b
  e_world_time_hour.b
  e_world_time_tick.i ;tickrate for seconds counter....
  e_world_time_actual_ticker.i  ;stores the elapsedms+e_world_time_tick... if elapsedms > e_world_time_actual_ticker we actualise the value
  e_world_time_start_hour.b
  e_world_time_start_minute.b
  e_world_time_start_second.b
  e_world_time_start_day.b    ;hour
  e_world_time_start_night.b  ;hour
  e_world_time_days_player_in_game.i ;we use this for some statistics 
  e_world_time_days_in_game.i        ; maybe some other world relevant actions
  e_world_time_save_path.s
  e_world_time_maximal_days_per_year.i
EndStructure
  
;---for the xp multiplikator 
;every kill of object is added +1, timer reduces multiplactor by -1
Structure e_xp_multiplicator
 e_xp_multiplicator.f
 e_xp_multiplicator_add.f
 e_xp_multiplicator_reduce.f
 e_xp_multiplicator_timer.i
 e_xp_multiplicator_actual_time.i
 e_xp_multiplicator_text_y.f 
 e_xp_multiplicator_text_x.f
 e_xp_multiplicator_text_y_move.f
 e_xp_multiplicator_text_move_maximum.f
 e_xp_multiplicator_font_name.s
 e_xp_mutliplicator_font_size.f
 e_xp_actual_move_counter.f
 EndStructure

 ;--engine inbuild effects
 Structure  e_engine_build_in_effect
   e_sound_disk_drive_valid.b
   e_sound_disk_drive_id.i
   e_sound_disk_drive_path.s
   e_sound_disk_drive_play.b
   e_frame_is_ready.b
   e_sgfx_effect_do.b
   e_sgfx_effect_timer.i
   e_sgfx_effect_time.i
   e_sgfx_effect_dynamic_timer.i
   e_sgfx_effect_mode.i
   e_frame_id.i
   e_frame_rate.i
   e_sgfx_object_counter.i
   EndStructure 
 
 ;---player_warning
 Structure e_player_warning
   e_player_warning_text_german.s
   e_player_warning_text_english.s  ;default
   e_player_warning_show.b
   e_player_warning_show_time.i
   e_player_warning_show_time_max.i
   e_player_warning_text_move_y_counter_max.f
   e_player_warning_text_move_y_counter_step.f
   e_player_warning_text_move_y_actual_pos.f
   e_player_warning_text_y.f
   e_player_warning_text_x.f
 EndStructure
 
  ;--worldinfosystem
 Structure e_world_info_system
   world_info_system_map_name.s  ;represents the map name shown on screen
   world_info_system_map_screen_name.s
   world_info_system_map_name_pos_x.f
   world_info_system_map_name_pos_y.f
   world_info_system_map_name_line_offset.f
   world_info_system_permanent_text.s
   world_info_system_permanent_text_x.f
   world_info_system_permanent_text_y.f
   rgb_r.i
   rgb_g.i
   rgb_b.i
   rgb_r_map.i
   rgb_g_map.i
   rgb_b_map.i
 EndStructure
 
 ;--engine textsystem (ascii)
 Structure engine_text_system
   engine_text_string.s
   engine_text_pos_x.f
   engine_text_pos_y.f
   engine_text_color_RGB.i
   engine_text_color_red.i
   engine_text_color_green.i
   engine_text_color_blue.i
 EndStructure
 
 ;--custmmessagerequester
 Structure e_engine_custom
   custom_msg_requester_titel.s
   custom_msg_requester_pos_x.f
   custom_msg_requester_pos_y.f
   custom_msg_requester_text.s
   custom_msg_requester_back_gfx_id.i  ;backgroundgfx
   custom_msg_requester_back_gfx_path.s
   custom_msg_requester_button_yes_id.i
   custom_msg_requester_button_no_id.i
   custom_msg_requester_button_yes_path.s
   custom_msg_requester_button_no_path.s
   custom_button_no_x.f  ;absolute to msg requester position
   custom_button_no_y.f
   custom_button_yes_x.f
   custom_button_yes_y.f
   custom_msg_requester_width.f
   custom_msg_requester_height.f
   custom_msg_requester_font_head.s
   custom_msg_reqester_font_size_head.f
   custom_msg_requester_font_color_RGB.i
   custom_msg_requester_gfx_core_path.s  ;fundament for gfx loading
   custom_extension_core_path.s
   custom_msg_requester_transparency.f
   custom_msg_reqester_font_size_body.f
   custom_msg_requester_font_body.s
   custom_msg_requester_sound_id.i
   custom_msg_requester_sound_path.s
   custom_msg_requester_msg.i
   
 EndStructure
 
 ;---local daynight cycle
 Structure day_night_cycle
   light_intensity_actual.f
   light_intensity_max.f
   light_intensity_min.f
   light_color_actual_r.i
   light_color_actual_g.i
   light_color_actual_b.i
   light_color_r.i
   light_color_g.i
   light_color_b.i
   light_color_RGB.i
   ticks.i  ;size of counter 
   ;for some dynamic light effects
   light_source_RGB.i
   light_source_r.i
   light_source_g.i
   light_source_b.i
   light_mask_id.i  ;for the light effect we use a sprite 
   light_mask_source.s
 EndStructure 
 
 ;--global daynighcycle
  Structure global_day_night_cycle
   light_intensity_actual.f
   light_intensity_max.f
   light_intensity_min.f
 EndStructure 
 
 ;--hitblink
 Structure hit_blink
   hit_blink_time_ms.i
   hit_blink_color_r.i
   hit_blink_color_g.i
   hit_blink_color_b.i
   hit_blink_intensity.i
  EndStructure
  
;--indexer
Structure indexerC
  *index  ;store the pointer of worldwobject 
EndStructure

Structure indexeI
  *index
EndStructure

;---map_timer
Structure e_map_timer
  _next_map.s
  _map_time.i
  _map_time_stop.i
  _map_timer_symbol_gfx_id.i
  _map_time_gfx_pos_x.f
  _map_time_gfx_pos_y.f
  _map_time_text_pos_x.f
  _map_time_text_pos_y.f
  _map_timer_font_id.i
  _map_timer_font_size.f
  _map_timer_font_name.s
  _map_timer_font_size_dynamic.b
  _map_time_text_position_font_small_x.f
  _map_time_text_position_font_small_y.f
EndStructure

;---grabscreen
Structure grab_screen
  screen_src_id.i
  screen_des_id.i
  screen_pos_x.f
  screen_pos_y.f
  screen_src_transparency.f
  screen_des_transparency.f
  screen_transparency_change_speed.f
  screen_is_active.b
EndStructure

;--fileintegrity
 Structure file_integrity
   patch_file_list_path.s  ;holds the path of the patchfile list 
   patch_file_actual_object.s
 EndStructure

 ;---stamp_mask
 Structure stamp_mask_buffer
   back_buffer_id.i
   back_buffer_path.s
   back_buffer_resize.b
   back_buffer_target_size_x.f
   back_buffer_target_size_y.f
   back_buffer_transparency.i
    EndStructure
 
 ;---engine game type
 Structure e_engine_game_type
   engine_gravity.f
   engine_mode_is_jump_and_run.i
   engine_mode_is_world_mode.i
   engine_use_left_barier.b
   engine_use_block_scroll.b
   engine_block_size_x.f
   engine_block_size_y.f
   
 EndStructure
 
 ;--virtualkeyboard
 Structure e_vkey
   v_key_ascii_code.l
   v_key_gfx_id.i
   v_key_gfx_alternative_id.i
   v_key_gfx_id_transparency.f
   v_key_gfx_alternative_id_transparency.f
   v_key_pos_x.f
   v_key_pos_y.f
   v_key_width.f
   v_key_height.f
   v_key_select_sound_id.i
   v_key_select_sound_volume.i 
   v_key_blank_gfx_id.i
   v_key_key_text.s
    EndStructure
    
    Structure e_world_shake
      world_shake_horizontal.i
      world_shake_vertical.i
      world_shake_base_horizontal.i ;hold the initial settings
      world_shake_base_vertical.i ;hold the initial settings
     EndStructure
 
    Structure brain
      e_internal_name1.s
      e_internal_name2.s
      *e_object_system_id1
      *e_object_system_id2
      e_collision_id1.i
      e_collision_id2.i
      e_internal_object_1_attack.i
      e_internal_object_2_attack.i
         
    EndStructure
    
    Structure e_engine_heart_beat
      beats_since_start.i
      heart_rate.i ;use this as an factor for effective duration, so we calculate engine time to realtime base: 1000ms
    EndStructure
    
    Structure e_engine_global_effects
      global_effect_flash_light_status.i
      global_effect_flash_light_color_RGB.i
      global_effect_flash_light_color_R.i
      global_effect_flash_light_color_G.i
      global_effect_flash_light_color_B.i
      global_effect_flash_light_intensity.i
      global_effect_flash_light_layer.i
      global_effect_flash_light_intensity_dynamic.i
      global_effect_global_light_status.i
      global_effect_global_light_intensity.i
      global_effect_global_light_color_RGB.i
      global_effect_global_light_color_R.i
      global_effect_global_light_color_G.i
      global_effect_global_light_color_B.i
      global_effect_global_light_layer.i
      global_effect_type_id.i
      global_effect_name.s
     
    EndStructure
        
    Structure e_GUI_font
      e_GUI_inventory_font_name.s
      e_GUI_inventory_font_size.f
      e_GUI_gold_font_name.s
      e_GUI_gold_font_size.f
      e_GUI_xp_font_name.s
      e_GUI_xp_font_size.f
      e_GUI_map_name_font_name.s
      e_GUI_map_name_font_size.f
      e_GUI_info_font_name.s
      e_GUI_info_font_size.f
      e_GUI_xp_text_font_name.s
      e_GUI_xp_text_font_name_size.f
      e_GUI_screen_head_font.s
      e_GUI_screen_head_font_size.f
      e_GUI_npc_font_name.s
      e_GUI_npc_font_size.f
      e_GUI_debug_font_name.s
      e_GUI_debug_font_name_size.f
      e_GUI_font_name.s
      e_GUI_font_size.f
      e_GUI_player_overlay_font_name.s
      e_GUI_player_over_lay_font_size.f
    EndStructure
    
    Structure gfx_font
      gfx_font_object_text_id.i[255]  ;stores the gfx of the font object (for ascii system 0...255)
      gfx_font_object_digit_id.i[10] ;stores a digit block (0...9) used for digit repesentation on screen
      gfx_font_object_pos_x.f
      gfx_font_object_pos_y.f
      gfx_font_object_digit_path.s
      gfx_font_object_text_path.s
     EndStructure
          
     Structure e_version_info
       map_show_version_info.b
       version_info_text.s
       version_inf_x.f
       version_inf_y.f
       
     EndStructure
     
     Structure e_ingame_info_text
       text.s
       x.f
       y.f
       r.i
       g.i
       b.i
       show.b
       show_time.i
       timer.i
     EndStructure
     
     Structure e_engine_world_control  ;here we do scrolling and other world object manipulation (global)
       world_map_scroll_direction.i
       world_map_scroll_speed_x.f
       world_map_scroll_speed_y.f
       use_global_scroll.b
     EndStructure
         
     Structure e_engine_core
       core_is_started.b
       core_start_identifier_location.s  ;holds the file path of the "core info",this file is created if engine is started and deleted if engine is quit, if engine crashes you may delete the "core info" file to (re)start engine   
     EndStructure
     
     Structure game_file_list
       full_path.s
     EndStructure
     
 
; -------------------------------------------------------------  

Global NewList world_object.world_objects()
Global NewList indexeI.indexeI()
Global NewList pool_map.maps()  ;here we store the mapfiles
Global NewList engine_text_system.engine_text_system()
Global NewList indexerC.indexerC()
Global NewList auto_switch_map.auto_switch_map()

Global e_GUI_font.e_GUI_font
Global gfx_font.gfx_font
Global e_engine_game_type.e_engine_game_type
Global global_day_night_cycle.global_day_night_cycle
Global day_night_cycle.day_night_cycle
Global e_world_time.e_world_time
Global player_statistics.player_statistics
Global npc_text.npc_text
Global npc_confy.npc_confy
Global e_xp_multiplicator.e_xp_multiplicator
Global e_player_warning.e_player_warning
Global e_world_object.e_world_object
Global e_world_info_system.e_world_info_system
Global boss_bar.boss_bar
Global button_sound.button_sound
Global e_engine_custom.e_engine_custom
Global grab_screen.grab_screen
Global e_engine_build_in_effect.e_engine_build_in_effect
Global file_integrity.file_integrity
Global e_map_timer.e_map_timer
Global hit_blink.hit_blink
Global stamp_mask_buffer.stamp_mask_buffer
Global brain.brain
Global e_engine_heart_beat.e_engine_heart_beat
Global e_engine_global_effects.e_engine_global_effects
Global e_version_info.e_version_info
Global e_ingame_info_text.e_ingame_info_text
Global e_engine_world_control.e_engine_world_control
Global e_world_shake.e_world_shake
Global e_engine_core.e_engine_core
e_player_warning\e_player_warning_show_time=3000  ;3 seconds ... use script o change this value

;-----------------put this in external script!!!
;default if no script:

e_engine_build_in_effect\e_sgfx_effect_timer=500
e_engine_build_in_effect\e_sgfx_effect_time=e_engine_heart_beat\beats_since_start+e_engine_build_in_effect\e_sgfx_effect_timer

;------------

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 1526
; FirstLine = 1504
; EnableThread
; EnableXP
; EnableUser
; EnableOnError
; CPU = 1
; DisableDebugger
; EnableCompileCount = 1
; EnableBuildCount = 0
; EnableExeConstant