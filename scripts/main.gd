
extends Node2D

@onready var jugador = $Player
@onready var enemigo = $Enemy

func _ready() -> void:
	enemigo.jugador = jugador
