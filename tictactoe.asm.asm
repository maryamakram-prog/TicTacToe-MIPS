
.data
title:       .asciiz "\n========================================\n          TIC TAC TOE\n           ULTIMATE EDITION\n========================================\n"
menu:        .asciiz "\nMAIN MENU\n----------------------------------------\n1. PLAYER vs PLAYER\n2. PLAYER vs COMPUTER\n3. HOW TO PLAY\n4. EXIT\n----------------------------------------\nEnter choice: "
modeMsg:     .asciiz "\nGAME MODE: "
pvpMsg:      .asciiz "TWO PLAYERS\n"
pvcMsg:      .asciiz "PLAYER vs COMPUTER\n"
boardTitle:  .asciiz "\n              GAME BOARD\n"
line:        .asciiz "       +-----+-----+-----+\n"
rowStart:    .asciiz "       |  "
separator:   .asciiz "  |  "
rowEnd:      .asciiz "  |\n"
turnMsg:     .asciiz "\nPlayer "
turnEnd:     .asciiz "'s turn.\n"
computerMsg: .asciiz "\nCOMPUTER is thinking...\n"
chooseMsg:   .asciiz "Enter cell number (1-9): "
invalidMsg:  .asciiz "\n[!] Invalid cell! Choose 1-9.\n"
occupiedMsg: .asciiz "\n[!] Cell already occupied!\n"
winX:        .asciiz "\n*** PLAYER X WINS! ***\n"
winO:        .asciiz "\n*** PLAYER O WINS! ***\n"
drawMsg:     .asciiz "\n*** IT'S A DRAW! ***\n"
scoreTitle:  .asciiz "\n          SCOREBOARD\n"
scoreX:      .asciiz "\nPlayer X Wins: "
scoreO:      .asciiz "\nPlayer O Wins: "
scoreD:      .asciiz "\nDraws: "
newline:     .asciiz "\n"
againMsg:    .asciiz "\n1. PLAY AGAIN\n2. MAIN MENU\n3. EXIT\nChoose: "
howTitle:    .asciiz "\n          HOW TO PLAY\n"
howText:     .asciiz "\n1. Board has 9 numbered cells.\n2. Enter a number from 1 to 9.\n3. Player X starts first.\n4. First player to make 3 in a row wins.\n5. Horizontal, vertical and diagonal wins count.\n6. Full board without a winner is a draw.\n7. In Computer mode, you play as X.\n"
goodbye:     .asciiz "\nThanks for playing TIC TAC TOE!\n"
invalidMenu: .asciiz "\n[!] Invalid menu option. Try again.\n"

board:       .space 9

.text
.globl main

main:
    li $s1, 0
    li $s2, 0
    li $s3, 0

mainMenu:
    li $v0, 4
    la $a0, title
    syscall

    li $v0, 4
    la $a0, menu
    syscall

    li $v0, 5
    syscall
    move $t0, $v0

    beq $t0, 1, startPVP
    beq $t0, 2, startPVC
    beq $t0, 3, instructions
    beq $t0, 4, exitGame

    li $v0, 4
    la $a0, invalidMenu
    syscall
    j mainMenu

instructions:
    li $v0, 4
    la $a0, howTitle
    syscall

    li $v0, 4
    la $a0, howText
    syscall
    j mainMenu

startPVP:
    li $s0, 1

    li $v0, 4
    la $a0, modeMsg
    syscall

    li $v0, 4
    la $a0, pvpMsg
    syscall
    j newGame

startPVC:
    li $s0, 2

    li $v0, 4
    la $a0, modeMsg
    syscall

    li $v0, 4
    la $a0, pvcMsg
    syscall

newGame:
    jal resetBoard
    li $s4, 88

gameLoop:
    jal displayBoard

    li $t0, 79
    beq $s0, 2, checkComputer
    j humanTurn

checkComputer:
    beq $s4, $t0, computerTurn

humanTurn:
    li $v0, 4
    la $a0, turnMsg
    syscall

    li $v0, 11
    move $a0, $s4
    syscall

    li $v0, 4
    la $a0, turnEnd
    syscall

    li $v0, 4
    la $a0, chooseMsg
    syscall

    li $v0, 5
    syscall

    blt $v0, 1, invalidMove
    bgt $v0, 9, invalidMove

    addi $t1, $v0, -1
    la $t2, board
    addu $t2, $t2, $t1

    lb $t3, 0($t2)

    li $t4, 88
    beq $t3, $t4, occupiedMove

    li $t4, 79
    beq $t3, $t4, occupiedMove

    sb $s4, 0($t2)
    j moveCompleted

invalidMove:
    li $v0, 4
    la $a0, invalidMsg
    syscall
    j gameLoop

occupiedMove:
    li $v0, 4
    la $a0, occupiedMsg
    syscall
    j gameLoop

# QTSpim computer logic: select first available cell
computerTurn:
    li $v0, 4
    la $a0, computerMsg
    syscall

    la $t2, board
    li $t1, 0

computerSearch:
    lb $t3, 0($t2)

    li $t4, 88
    beq $t3, $t4, computerNext

    li $t4, 79
    beq $t3, $t4, computerNext

    li $t4, 79
    sb $t4, 0($t2)
    j moveCompleted

computerNext:
    addi $t2, $t2, 1
    addi $t1, $t1, 1
    blt $t1, 9, computerSearch

moveCompleted:
    jal checkResult

    beq $v0, 88, xWon
    beq $v0, 79, oWon
    beq $v0, 68, gameDraw

    li $t0, 88
    beq $s4, $t0, changeToO

    li $s4, 88
    j gameLoop

changeToO:
    li $s4, 79
    j gameLoop

xWon:
    jal displayBoard

    li $v0, 4
    la $a0, winX
    syscall

    addi $s1, $s1, 1
    j endRound

oWon:
    jal displayBoard

    li $v0, 4
    la $a0, winO
    syscall

    addi $s2, $s2, 1
    j endRound

gameDraw:
    jal displayBoard

    li $v0, 4
    la $a0, drawMsg
    syscall

    addi $s3, $s3, 1

endRound:
    jal displayScore

    li $v0, 4
    la $a0, againMsg
    syscall

    li $v0, 5
    syscall

    beq $v0, 1, newGame
    beq $v0, 2, mainMenu
    beq $v0, 3, exitGame
    j mainMenu

resetBoard:
    la $t0, board
    li $t1, 49
    li $t2, 9

resetLoop:
    sb $t1, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t2, $t2, -1
    bgtz $t2, resetLoop
    jr $ra

displayBoard:
    li $v0, 4
    la $a0, boardTitle
    syscall

    li $v0, 4
    la $a0, line
    syscall

    la $t0, board
    li $t1, 0

displayLoop:
    li $v0, 4
    la $a0, rowStart
    syscall

    lb $a0, 0($t0)
    li $v0, 11
    syscall

    li $v0, 4
    la $a0, separator
    syscall

    lb $a0, 1($t0)
    li $v0, 11
    syscall

    li $v0, 4
    la $a0, separator
    syscall

    lb $a0, 2($t0)
    li $v0, 11
    syscall

    li $v0, 4
    la $a0, rowEnd
    syscall

    li $v0, 4
    la $a0, line
    syscall

    addi $t0, $t0, 3
    addi $t1, $t1, 1
    blt $t1, 3, displayLoop
    jr $ra

checkResult:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $a0, 0
    li $a1, 1
    li $a2, 2
    jal checkLine
    bnez $v0, resultDone

    li $a0, 3
    li $a1, 4
    li $a2, 5
    jal checkLine
    bnez $v0, resultDone

    li $a0, 6
    li $a1, 7
    li $a2, 8
    jal checkLine
    bnez $v0, resultDone

    li $a0, 0
    li $a1, 3
    li $a2, 6
    jal checkLine
    bnez $v0, resultDone

    li $a0, 1
    li $a1, 4
    li $a2, 7
    jal checkLine
    bnez $v0, resultDone

    li $a0, 2
    li $a1, 5
    li $a2, 8
    jal checkLine
    bnez $v0, resultDone

    li $a0, 0
    li $a1, 4
    li $a2, 8
    jal checkLine
    bnez $v0, resultDone

    li $a0, 2
    li $a1, 4
    li $a2, 6
    jal checkLine
    bnez $v0, resultDone

    li $t0, 0
    la $t1, board
    li $t2, 9

drawCheck:
    lb $t3, 0($t1)

    li $t4, 88
    beq $t3, $t4, nextDrawCell

    li $t4, 79
    beq $t3, $t4, nextDrawCell

    j continueGame

nextDrawCell:
    addi $t1, $t1, 1
    addi $t0, $t0, 1
    blt $t0, $t2, drawCheck

    li $v0, 68
    j resultDone

continueGame:
    li $v0, 0

resultDone:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

checkLine:
    la $t0, board

    addu $t1, $t0, $a0
    lb $t2, 0($t1)

    addu $t1, $t0, $a1
    lb $t3, 0($t1)

    addu $t1, $t0, $a2
    lb $t4, 0($t1)

    bne $t2, $t3, noLine
    bne $t3, $t4, noLine

    li $t5, 88
    beq $t2, $t5, lineFound

    li $t5, 79
    beq $t2, $t5, lineFound

noLine:
    li $v0, 0
    jr $ra

lineFound:
    move $v0, $t2
    jr $ra

displayScore:
    li $v0, 4
    la $a0, scoreTitle
    syscall

    li $v0, 4
    la $a0, scoreX
    syscall

    li $v0, 1
    move $a0, $s1
    syscall

    li $v0, 4
    la $a0, scoreO
    syscall

    li $v0, 1
    move $a0, $s2
    syscall

    li $v0, 4
    la $a0, scoreD
    syscall

    li $v0, 1
    move $a0, $s3
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    jr $ra

exitGame:
    li $v0, 4
    la $a0, goodbye
    syscall

    li $v0, 10
    syscall
