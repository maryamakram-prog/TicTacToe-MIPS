
from flask import Flask, jsonify, request, render_template
import subprocess
import re
import os

app = Flask(__name__)

# ==========================================
# CONFIGURATION
# ==========================================

MARS_JAR = r"C:\Users\NGCs\Downloads\Mars4_5\Mars.jar"
ASM_FILE = r"C:\Users\NGCs\Desktop\TicTacToe-MIPS\tictactoe.asm.asm"

game_mode = 1
move_history = []
current_state = None


# ==========================================
# MIPS SIMULATOR
# ==========================================

def run_mips(mode, moves):

    if not os.path.isfile(MARS_JAR):
        raise FileNotFoundError("MARS JAR file not found.")

    if not os.path.isfile(ASM_FILE):
        raise FileNotFoundError("MIPS assembly file not found.")

    inputs = [str(mode)] + [str(move) for move in moves]
    input_data = "\n".join(inputs) + "\n"

    try:
        result = subprocess.run(
            ["java", "-jar", MARS_JAR, "nc", ASM_FILE],
            input=input_data,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=15
        )

    except subprocess.TimeoutExpired:
        raise RuntimeError("MARS execution timed out.")

    except Exception as error:
        raise RuntimeError(f"Could not launch MARS: {error}")

    output = result.stdout or ""
    error_output = result.stderr or ""

    # Read board from MIPS output
    row_pattern = re.compile(
        r"\|\s*([XO1-9])\s*\|\s*([XO1-9])\s*\|\s*([XO1-9])\s*\|"
    )

    rows = row_pattern.findall(output)

    if len(rows) < 3:
        raise RuntimeError(
            "Could not extract the MIPS board.\n"
            "MARS output:\n" + output[-2000:] +
            "\nMARS errors:\n" + error_output[-1000:]
        )

    latest_rows = rows[-3:]
    cells = [cell for row in latest_rows for cell in row]

    # Detect winner
    winner = None

    if re.search(r"PLAYER\s+X\s+WINS", output, re.IGNORECASE):
        winner = "X"

    elif re.search(r"PLAYER\s+O\s+WINS", output, re.IGNORECASE):
        winner = "O"

    elif re.search(r"\bDRAW\b|\bTIE\b", output, re.IGNORECASE):
        winner = "Draw"

    # Next player
    if winner:
        next_player = None

    elif mode == 2:
        next_player = "X"

    else:
        next_player = "O" if len(moves) % 2 == 1 else "X"

    return {
        "board": cells,
        "winner": winner,
        "next_player": next_player,
        "output": output
    }


# ==========================================
# HOME - FRONTEND
# ==========================================

@app.route("/")
def home():
    return render_template("index.html")


# ==========================================
# START NEW GAME
# ==========================================

@app.route("/api/new", methods=["POST"])
def new_game():

    global game_mode, move_history, current_state

    data = request.get_json(silent=True) or {}
    mode = data.get("mode", 1)

    if type(mode) is not int or mode not in (1, 2):
        return jsonify({
            "success": False,
            "error": "Mode must be 1 or 2."
        }), 400

    game_mode = mode
    move_history = []
    current_state = None

    try:
        current_state = run_mips(game_mode, move_history)

        return jsonify({
            "success": True,
            "mode": game_mode,
            "board": current_state["board"],
            "winner": current_state["winner"],
            "next_player": current_state["next_player"]
        })

    except Exception as error:
        return jsonify({
            "success": False,
            "error": str(error)
        }), 500


# ==========================================
# PLAYER MOVE
# ==========================================

@app.route("/api/move", methods=["POST"])
def make_move():

    global move_history, current_state

    data = request.get_json(silent=True) or {}
    cell = data.get("cell")

    if type(cell) is not int or cell < 1 or cell > 9:
        return jsonify({
            "success": False,
            "error": "Choose a cell between 1 and 9."
        }), 400

    if current_state is None:
        return jsonify({
            "success": False,
            "error": "Start a new game first."
        }), 400

    if current_state["winner"]:
        return jsonify({
            "success": False,
            "error": "This game has already finished."
        }), 400

    if current_state["board"][cell - 1] in ("X", "O"):
        return jsonify({
            "success": False,
            "error": "This cell is already occupied."
        }), 400

    try:
        move_history.append(cell)

        current_state = run_mips(game_mode, move_history)

        return jsonify({
            "success": True,
            "board": current_state["board"],
            "winner": current_state["winner"],
            "next_player": current_state["next_player"]
        })

    except Exception as error:

        if move_history and move_history[-1] == cell:
            move_history.pop()

        return jsonify({
            "success": False,
            "error": str(error)
        }), 500


# ==========================================
# GAME STATE
# ==========================================

@app.route("/api/state", methods=["GET"])
def get_state():

    return jsonify({
        "server": "running",
        "simulator": os.path.isfile(MARS_JAR),
        "assembly": os.path.isfile(ASM_FILE),
        "mode": game_mode,
        "board": (
            current_state["board"]
            if current_state else None
        ),
        "winner": (
            current_state["winner"]
            if current_state else None
        )
    })


# ==========================================
# RESET GAME
# ==========================================

@app.route("/api/reset", methods=["POST"])
def reset_game():
    return new_game()


# ==========================================
# RUN SERVER
# ==========================================

if __name__ == "__main__":

    print("\n======================================")
    print("       TIC TAC TOE - MIPS BRIDGE")
    print("======================================")

    print("MARS JAR:", os.path.isfile(MARS_JAR))
    print("MIPS FILE:", os.path.isfile(ASM_FILE))

    print("\nStarting Flask server...")
    print("Open: http://127.0.0.1:5000")

    app.run(
        host="127.0.0.1",
        port=5000,
        debug=False,
        threaded=False
    )
