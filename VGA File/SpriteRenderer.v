module SpriteRenderer #(
    parameter NUM_OBJECTS = 3,
    parameter OBJ_TABLE_BASE = 0,
    parameter SPRITE_DATA_START = 12 // (3 objects * 4 bytes) = 12
)(
    input  wire        clk,
    input  wire        rst, 
    input  wire [9:0]  hCount,
    input  wire [9:0]  vCount,
    input  wire        bright,

    // BRAM port A
    output reg  [9:0]  bram_addr,
    input  wire [15:0] bram_data,

    // pixel output
    output reg  [3:0]  r,
    output reg  [3:0]  g,
    output reg  [3:0]  b
);

    // ----------------------------
    // Object Storage (Cache)
    // ----------------------------
    reg [9:0]  obj_x       [0:NUM_OBJECTS-1];
    reg [9:0]  obj_y       [0:NUM_OBJECTS-1];
    reg [2:0]  obj_palette [0:NUM_OBJECTS-1];
    // 64-bit register stores the 8x8 sprite pattern (8 rows * 8 bits)
    reg [63:0] obj_bitmap  [0:NUM_OBJECTS-1]; 

    integer i;

    // ----------------------------
    // Loading State Machine
    // ----------------------------
    // 0=X, 1=Y, 2=ID, 3=Pal, 4-11=SpriteRows
    reg [3:0] load_state;   
    reg [1:0] pipeline_wait;
    reg [3:0] obj_index;
    reg       loading_data;
    
    // Temporary holder for the sprite ID read in step 2
    reg [7:0] current_sprite_id; 

    // ----------------------------
    // Render Variables
    // ----------------------------
    reg       pixel_drawn;
    reg [9:0] sx, sy; // Signed to allow calculating offsets
    reg [3:0] r_next, g_next, b_next;

    // ----------------------------
    // BRAM Pipeline Simulation
    // ----------------------------
    reg [15:0] bram_data_pipe;

    // ----------------------------
    // Initialization / Reset
    // ----------------------------
    always @(posedge clk) begin
        if (!rst) begin
            load_state    <= 0;
            obj_index     <= 0;
            loading_data  <= 1'b1;
            pipeline_wait <= 0;
            current_sprite_id <= 0;
        end 
        else if (loading_data) begin
            // ----------------------------------------
            // LOADING LOGIC (Runs once at startup)
            // ----------------------------------------
            
            // Toggle wait state to account for BRAM latency
            // 0: Set Address, 1: Read Data
            pipeline_wait <= pipeline_wait + 1;

            if (pipeline_wait == 1) begin
                // We have valid data now, store it
                case(load_state)
                    0: obj_x[obj_index]       <= bram_data[9:0]; // Use bram_data directly if wait=1
                    1: obj_y[obj_index]       <= bram_data[9:0];
                    2: current_sprite_id      <= bram_data[7:0]; // Save ID to calculate offsets next
                    3: obj_palette[obj_index] <= bram_data[2:0];
                    // States 4 to 11 load the 8 rows of sprite pixels
                    default: begin
                        // Map state 4->Row 0, State 11->Row 7
                        // We shift the data into the 64-bit bitmap register
                        // This stores row 0 at bits [7:0], row 1 at [15:8], etc.
                        obj_bitmap[obj_index][((load_state - 4) * 8) +: 8] <= bram_data[7:0];
                    end
                endcase

                // Advance State
                if (load_state == 11) begin
                    load_state <= 0;
                    if (obj_index == NUM_OBJECTS - 1)
                        loading_data <= 1'b0; // Done loading everything
                    else
                        obj_index <= obj_index + 1;
                end else begin
                    load_state <= load_state + 1;
                end
            end
        end
    end

    // ----------------------------
    // Address Generation
    // ----------------------------
    always @(*) begin
        if (loading_data) begin
            if (load_state < 4) begin
                // Reading the Object Header (X, Y, ID, Pal)
                bram_addr = OBJ_TABLE_BASE + (obj_index * 4) + load_state;
            end else begin
                // Reading the Sprite Pixel Data (Rows 0-7)
                // Addr = Table_End + (SpriteID * 8) + Row_Offset
                // Note: Ensure your BRAM contains the sprite bitmaps AFTER the object table!
                bram_addr = OBJ_TABLE_BASE + (NUM_OBJECTS * 4) + (current_sprite_id * 8) + (load_state - 4);
            end
        end else begin
            bram_addr = 0; // Don't care when drawing
        end
    end

    // ----------------------------
    // Drawing Logic (Runs every pixel)
    // ----------------------------
    always @(posedge clk) begin
        // Default Background (White)
        r_next <= 4'hF;
        g_next <= 4'hF;
        b_next <= 4'hF;
        pixel_drawn <= 1'b0;

        if (!loading_data) begin
            for (i = 0; i < NUM_OBJECTS; i = i + 1) begin
                // If we haven't drawn a pixel yet (priority logic)...
                if (!pixel_drawn) begin
                    // Check if hCount/vCount is inside the sprite box
                    // Using simple math; ensure hCount/vCount are 10-bit
                    if (hCount >= obj_x[i] && hCount < (obj_x[i] + 8) &&
                        vCount >= obj_y[i] && vCount < (obj_y[i] + 8)) 
                    begin
                        
                        sx = hCount - obj_x[i]; // Column (0-7)
                        sy = vCount - obj_y[i]; // Row (0-7)
                        
                        // Check the cached bitmap
                        // ((sy * 8) + (7 - sx)) handles indexing:
                        // sy * 8 selects the row
                        // 7 - sx selects the bit (assuming bit 7 is left-most pixel)
                        if (obj_bitmap[i][(sy * 8) + (7 - sx)]) begin
                            case(obj_palette[i])
                                0: {r_next,g_next,b_next} <= 12'h000; // Black
                                1: {r_next,g_next,b_next} <= 12'hF00; // Red
                                2: {r_next,g_next,b_next} <= 12'h0F0; // Green
                                3: {r_next,g_next,b_next} <= 12'h00F; // Blue
                                4: {r_next,g_next,b_next} <= 12'h0FF; // Cyan
                                5: {r_next,g_next,b_next} <= 12'hF0F; // Magenta
                                6: {r_next,g_next,b_next} <= 12'hFF0; // Yellow
                                7: {r_next,g_next,b_next} <= 12'hAAA; // Grey
                            endcase
                        end
                        
                        pixel_drawn <= 1'b1; // Mark as drawn so background/lower sprites don't overwrite
                    end
                end
            end
        end

        // ----------------------------
        // Final VGA Output Mux
        // ----------------------------
        if (bright) begin
            r <= r_next;
            g <= g_next;
            b <= b_next;
        end else begin
            r <= 0; g <= 0; b <= 0;
        end
    end

endmodule
