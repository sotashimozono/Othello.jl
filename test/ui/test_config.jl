using Test
using Reversi
using TOML

@testset "Configuration System" begin
    @testset "Color Parsing" begin
        # 6-char hex
        c = Reversi.parse_color("#123456")
        @test length(c) == 3
        @test c[1] ≈ 0x12 / 255.0f0
        @test c[2] ≈ 0x34 / 255.0f0
        @test c[3] ≈ 0x56 / 255.0f0

        # 8-char hex (RGBA)
        c = Reversi.parse_color("#11223344")
        @test length(c) == 4
        @test c[1] ≈ 0x11 / 255.0f0
        @test c[2] ≈ 0x22 / 255.0f0
        @test c[3] ≈ 0x33 / 255.0f0
        @test c[4] ≈ 0x44 / 255.0f0

        # Fallback
        c = Reversi.parse_color("invalid")
        @test c == (0.0f0, 0.0f0, 0.0f0)
    end

    @testset "Config Loading" begin
        # Default config
        config = load_config()
        @test config isa GUIConfig
        @test !isempty(config.window_title)
        @test config.window_width > 0
        @test config.colors isa Dict
    end

    @testset "Environment Overrides" begin
        # Override board color via ENV
        withenv("REVERSI_COLORS_BOARD" => "#ff0000") do
            config = load_config()
            @test config.colors["board"] == "#ff0000"
        end

        # Test composite key override
        withenv("REVERSI_UI_FONTSIZE" => "20") do
            config = load_config()
            @test config.fontsize == 20
        end

        withenv("REVERSI_UI_SHOW_HINTS" => "false") do
            config = load_config()
            @test config.show_hints === false
        end
    end

    @testset "Session Persistence" begin
        config = load_config()
        original_hints = config.show_hints

        # Toggle and save
        config.show_hints = !original_hints
        save_session_config(config)

        # Load again and verify
        new_config = load_config()
        @test new_config.show_hints == !original_hints

        # Clean up session file if it existed
        if isfile(Reversi.SESSION_CONFIG_PATH)
            rm(Reversi.SESSION_CONFIG_PATH)
        end

        # Restore and verify it's back to default/user setting
        restored_config = load_config()
        @test restored_config.show_hints == original_hints
    end
end
