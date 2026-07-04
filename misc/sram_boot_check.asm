; we store certain variables in uninitialised SRAM in order to persist them across sessions
; their initial state is therefore undefined, so this routine is used to force correct them if needed
sram_boot_check:
    PHP
    %a8()

    JSR bindings_boot_check
    JSR warp_presets_boot_check

    LDA #$FF : STA !save_level ; initial state = no savestate

    LDA !debug_control_scheme : BEQ + : CMP #$02 : BEQ +
    LDA #$00 : STA !debug_control_scheme
    +
    LDA !disable_music : BEQ + : CMP #$01 : BEQ +
    LDA #$00 : STA !disable_music
    +
    LDA !exception_handler_enabled : BEQ + : CMP #$01 : BEQ +
    LDA #$00 : STA !exception_handler_enabled
    +
    LDA !full_load_default : BEQ + : CMP #$01 : BEQ +
    LDA #$00 : STA !full_load_default
    +
    LDA !enable_yoshi_custom_palette : BEQ + : CMP #$01 : BEQ +
    LDA #$00 : STA !enable_yoshi_custom_palette
    +
    %a16()
    LDA !skip_kamek : BEQ + : CMP #$0001 : BEQ +
    LDA #$0000 : STA !skip_kamek
    +
.ret
    PLP
    RTL

; calculate CRC16 checksum over the warp_presets SRAM block
; RETURNS: A = checksum (16-bit)
get_warp_presets_checksum:
    PHP
    %a16()
    %i8()
    LDA #!warp_presets : STA !gsu_r10       ; input: r10 = starting address (bank $70 implied)
    LDA.w #!warp_preset_stride*5 : STA !gsu_r12 ; input: r12 = size in bytes ($5A = 90)
    LDX.b #<:generic_checksum
    LDA #generic_checksum
    JSL r_gsu_init_1
    LDA !gsu_r0                             ; output: r0 = checksum
.ret
    PLP
    RTS

; check warp presets checksum at boot; zero the presets if mismatched (corrupt/uninitialised SRAM)
warp_presets_boot_check:
    PHP
    %a16()
    JSR get_warp_presets_checksum
    CMP !warp_presets_checksum
    BEQ .ret
    ; mismatch - zero-initialise all preset slots and store a fresh checksum
    LDA #$0000
    LDX #!warp_preset_stride*5-2
  - STA.l !warp_presets,x
    DEX #2
    BPL -
    ; the all-zero block has a deterministic checksum; compute and store it
    JSR get_warp_presets_checksum
    STA !warp_presets_checksum
.ret
    PLP
    RTS
