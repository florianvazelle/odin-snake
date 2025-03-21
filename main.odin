package main

import fmt "core:fmt"
import rand "core:math/rand"
import time "core:time"
import rl "vendor:raylib"


// Constants

SQUARE_SIZE :: 8
BORDER :: SQUARE_SIZE * 4

SCREEN_WIDTH :: 512
SCREEN_HEIGHT :: 512

UP :: [2]i32{0, -SQUARE_SIZE}
RIGHT :: [2]i32{SQUARE_SIZE, 0}
LEFT :: [2]i32{-SQUARE_SIZE, 0}
DOWN :: [2]i32{0, SQUARE_SIZE}

// Game State

EntityType :: enum {
        Emtpy,
        Apple,
}

Entity :: struct {
        type: EntityType,
        pos:  [2]i32,
}

Body :: struct {
        pos: [2]i32,
        dir: [2]i32,
}

Snake :: struct {
        bodies: [dynamic]Body,
}

Game :: struct {
        snake:     Snake,
        items:     [15]Entity, // pool of apples
        score:     i32,
        game_over: bool,
        pause:     bool,
}

game: Game

background: rl.Shader
postpro_shader: rl.Shader
target : rl.RenderTexture2D

// Methods

main :: proc() {
        rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Snake")

        background = rl.LoadShader("", "shaders/checkboard.fs");
        postpro_shader = rl.LoadShader("", "shaders/vhs.fs");
        target = rl.LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT);

        init_game()

        rl.SetTargetFPS(60)

        tick_rate := 150 * time.Millisecond
        last_tick := time.now()

        // time_loc := rl.GetShaderLocation(postpro_shader, "time")

        // Main game loop
        for !rl.WindowShouldClose() {   // Detect window close button or ESC key
                handle_key()
                if time.since(last_tick) > tick_rate && !game.game_over && !game.pause {
                        last_tick = time.now()
                        update_game()
                }
                // delta := time.now()
                // rl.SetShaderValue(postpro_shader, rl.ShaderLocationIndex(time_loc), &delta, rl.ShaderUniformDataType.FLOAT)
        
                draw_game()
        }

        rl.UnloadShader(background);
        rl.UnloadShader(postpro_shader);
        rl.UnloadRenderTexture(target);
        rl.CloseWindow()
}


init_game :: proc() {
        length: i32 = 3

        game = Game{{}, {}, 0, false, false}

		game.score = 0
		game.game_over = false
		game.pause = false

        for i in 0 ..< length {
                append(
                        &game.snake.bodies,
                        Body{[2]i32{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2 + (i * SQUARE_SIZE)}, UP},
                )
        }

        generate_random_items(&game.items)
}

handle_key :: proc() {
        if game.game_over {
                if rl.IsKeyPressed(.ENTER) {
                        init_game()
                }
                return
        }

        if rl.IsKeyPressed(.P) {
                game.pause = !game.pause
        }

		if rl.IsKeyPressed(.R) {
				init_game()
				return
		}

        if game.pause {
                return
        }

        // Handle key events
        if rl.IsKeyPressed(.LEFT) {
                game.snake.bodies[0].dir = LEFT
        } else if rl.IsKeyPressed(.RIGHT) {
                game.snake.bodies[0].dir = RIGHT
        } else if rl.IsKeyPressed(.UP) {
                game.snake.bodies[0].dir = UP
        } else if rl.IsKeyPressed(.DOWN) {
                game.snake.bodies[0].dir = DOWN
        }
}

update_game :: proc() {
        create_tail := false
        delete_idx := 0
        remaining_apples := 0

        for item, idx in game.items {
                if item.type == .Apple {
                        remaining_apples += 1
                        if game.snake.bodies[0].pos[0] == item.pos[0] &&
                           game.snake.bodies[0].pos[1] == item.pos[1] {
                                create_tail = true
                                delete_idx = idx
                        }
                }
        }

        if create_tail {
                game.score += 1
                game.items[delete_idx].type = .Emtpy
        }

        if game.snake.bodies[0].pos[0] < BORDER ||
           SCREEN_WIDTH - BORDER <= game.snake.bodies[0].pos[0] ||
           game.snake.bodies[0].pos[1] < BORDER ||
           SCREEN_HEIGHT - BORDER <= game.snake.bodies[0].pos[1] {
                game.game_over = true
        } else {
                if remaining_apples == 0 {
                        generate_random_items(&game.items)
                }

                move_snake(create_tail)
        }
}

draw_game :: proc() {
        rl.BeginTextureMode(target); // Enable drawing to texture
                rl.ClearBackground(rl.BLANK)// Clear texture background

                rl.BeginShaderMode(background);
                        rl.DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_WIDTH, rl.WHITE); // Full-screen rectangle
                rl.EndShaderMode();

                rl.DrawText("@florianvazelle", SCREEN_WIDTH - 200, SCREEN_HEIGHT - 20, 26, rl.WHITE);

                rl.DrawLine(BORDER, BORDER, SCREEN_WIDTH - BORDER, BORDER, rl.WHITE)
                rl.DrawLine(
                        BORDER,
                        SCREEN_HEIGHT - BORDER,
                        SCREEN_WIDTH - BORDER,
                        SCREEN_HEIGHT - BORDER,
                        rl.WHITE,
                )
                rl.DrawLine(BORDER, BORDER, BORDER, SCREEN_HEIGHT - BORDER, rl.WHITE)
                rl.DrawLine(
                        SCREEN_WIDTH - BORDER,
                        BORDER,
                        SCREEN_WIDTH - BORDER,
                        SCREEN_HEIGHT - BORDER,
                        rl.WHITE,
                )

                if game.game_over {
                        text :: "PRESS [ENTER] TO PLAY AGAIN"
                        rl.DrawText(
                                text,
                                rl.GetScreenWidth() / 2 - rl.MeasureText(text, 20) / 2,
                                rl.GetScreenHeight() / 2 - 50,
                                40,
                                rl.WHITE,
                        )
                } else {
                        for item in game.items {
                                if item.type == .Apple {
                                        rl.DrawRectangle(item.pos[0], item.pos[1], SQUARE_SIZE, SQUARE_SIZE, rl.RED)
                                }
                        }

                        for body in game.snake.bodies {
                                rl.DrawRectangle(body.pos[0], body.pos[1], SQUARE_SIZE, SQUARE_SIZE, rl.GREEN)
                        }

                        if game.pause {
                                text :: "GAME PAUSED"
                                rl.DrawText(
                                        text,
                                        SCREEN_WIDTH / 2 - rl.MeasureText(text, 40) / 2,
                                        SCREEN_WIDTH / 2 - 40,
                                        40,
                                        rl.WHITE,
                                )
                        }

                        rl.DrawText(
                                rl.TextFormat("SCORE %d", game.score),
                                SQUARE_SIZE,
                                SQUARE_SIZE,
                                26,
                                rl.WHITE,
                        )

                }

        rl.EndTextureMode();             // End drawing to texture (now we have a texture available for next passes)
        
        //----------------------------------------------------------------------------------

        rl.BeginDrawing()
                rl.ClearBackground(rl.RAYWHITE)// Clear texture background

                // Render generated texture using selected postprocessing shader
                rl.BeginShaderMode(postpro_shader);
                        // NOTE: Render texture must be y-flipped due to default OpenGL coordinates (left-bottom)
                        rl.DrawTextureRec(target.texture, { 0, 0, cast(f32)target.texture.width,  cast(f32)-target.texture.height }, { 0, 0 }, rl.WHITE);
                rl.EndShaderMode();

        rl.EndDrawing()

}


move_snake :: proc(create_tail: bool) {
        new_dir := [2]i32{-1, -1}
        last_pos := [2]i32{-1, -1}

        for &body in game.snake.bodies {

                last_pos = body.pos

                body.pos[0] += body.dir[0]
                body.pos[1] += body.dir[1]

                tmp := body.dir
                if new_dir[0] != -1 && new_dir[1] != -1 {
                        body.dir = new_dir
                }
                new_dir = tmp
        }

        if create_tail {
                append(&game.snake.bodies, Body{last_pos, new_dir})
        }
}

generate_random_items :: proc(items: ^[15]Entity) {
        num := rand.int_max(10) + 5

        MIN :: 5
        MAX_X: int : (SCREEN_WIDTH) / SQUARE_SIZE - MIN * 2
        MAX_Y: int : (SCREEN_HEIGHT) / SQUARE_SIZE - MIN * 2

        for i in 0 ..< num {
                factor_x := cast(i32)rand.int_max(MAX_X) + MIN
                factor_y := cast(i32)rand.int_max(MAX_Y) + MIN

                items[i] = Entity{.Apple, [2]i32{SQUARE_SIZE * factor_x, SQUARE_SIZE * factor_y}}
        }
}