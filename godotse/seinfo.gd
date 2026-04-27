extends Node

class_name SEInfo

signal NoteData(id:String)
func NoteTrackData (id:String) -> void:
	emit_signal("NoteData",id)
