extends Node
class_name SEUtility
func store_max_val(f:FileAccess, r:int,s:int) -> void:
	if r <= 255:
		f.store_8(s)
	elif r <= 65535:
		f.store_16(s)
	else:
		f.store_32(s)
		
func read_max_val(f:FileAccess, r:int) -> int:
	if r <= 255:
		return f.get_8()
	elif r <= 65535:
		return f.get_16()
	else:
		return f.get_32()
func read_max_val_bytes(f:StreamPeerBuffer, r:int) -> int:
	if r <= 255:
		return f.get_8()
	elif r <= 65535:
		return f.get_16()
	else:
		return f.get_32()

func load_anim_from_path_with_rests(path:String,skeleton:Skeleton3D,animation_name:String,replace_existent_animations:bool,rests:Array) -> AnimationPlayer:
	var f:FileAccess = FileAccess.open(path,FileAccess.READ)
	if !f:
		push_error("the file could not be readen.")
		return
	
	var delta_tag_name:String = ""
	
	var magic:String = f.get_buffer(6).get_string_from_ascii()
	if magic != "SEAnim": #not a SEAnim file
		push_error("The file " + f.get_path().get_file() + " was not a SEAnim file, so it was skipped.")
		return
		
		
	var version:int = f.get_16()
	var header_size:int = f.get_16()
	var animation_type:int = f.get_8()
	var flags:int = f.get_8()
	
	var loops:bool = (flags & (1 << 0)) != 0;
	var presence_flag:int = f.get_8()
	var property_flag:int = f.get_8()
	f.seek(f.get_position()+2)
	var fps:float = f.get_float()
	var frame_count:int = f.get_32()
	var bone_count:int = f.get_32()
	var mod_count:int = f.get_8()
	f.seek(f.get_position()+3)
	var note_count:int = f.get_32()
	var bone_names:Array = strings_read(bone_count,f)
	if animation_type == 3:
		if len(bone_names) > 0:
			delta_tag_name = bone_names[0]
			
	var modifiers:Array = []
	for i:int in range(0,mod_count):
		var index:int = (f.get_8() if bone_count <= 255 else f.get_16())
		modifiers.append([index,f.get_8()])
		
		
	var double_precision:bool = property_flag & (1 << 0)
	var keys:Array = []
	for i:String in bone_names:
		var bone_flags:int = f.get_8()
		if presence_flag & 1 << 0: #got position keyframes!
			var keyframe_count:int = read_max_val(f,frame_count)
			for k:int in range(0,keyframe_count):
				var keyframe:int = read_max_val(f,frame_count)
				var vector:Vector3 = Vector3.ZERO
				if double_precision:
					vector.x = f.get_double()
					vector.y = f.get_double()
					vector.z = f.get_double()
				else:
					vector.x = f.get_float()
					vector.y = f.get_float()
					vector.z = f.get_float()
				keys.append(["position",i,keyframe,vector])
		if presence_flag & 1 << 1: #got rotation keyframes!
			var keyframe_count:int = read_max_val(f,frame_count)
			for k:int in range(0,keyframe_count):
				var keyframe:int = read_max_val(f,frame_count)
				var quaternion:Quaternion = Quaternion.IDENTITY
				if double_precision:
					quaternion.x = f.get_double()
					quaternion.y = f.get_double()
					quaternion.z = f.get_double()
					quaternion.w = f.get_double()
				else:
					quaternion.x = f.get_float()
					quaternion.y = f.get_float()
					quaternion.z = f.get_float()
					quaternion.w = f.get_float()
				keys.append(["rotation",i,keyframe,quaternion])
		if presence_flag & 1 << 2: #got scale keyframes!
			var keyframe_count:int = read_max_val(f,frame_count)
			for k:int in range(0,keyframe_count):
				var keyframe:int = read_max_val(f,frame_count)
				var vector:Vector3 = Vector3.ONE
				if double_precision:
					vector.x = f.get_double()
					vector.y = f.get_double()
					vector.z = f.get_double()
				else:
					vector.x = f.get_float()
					vector.y = f.get_float()
					vector.z = f.get_float()
				keys.append(["scale",i,keyframe,vector])

	var notes:Array = []
	for i:int in range(0,note_count):
		var keyframe:int = read_max_val(f,frame_count)
		var note:Array = strings_read(1,f)
		notes.append([keyframe,note])
		
	var ret_name:String = animation_name
	if ret_name == "":
		ret_name = f.get_path().get_file().replace("." + f.get_path().get_extension(),"")
	if skeleton.get_node_or_null("SEPlayer") != null:
		var anip:AnimationPlayer = skeleton.get_node_or_null("SEPlayer")
		for n:String in anip.get_animation_library_list():
			var anib:AnimationLibrary = anip.get_animation_library(n)
			if ret_name in anib.get_animation_list():
				if !replace_existent_animations:
					return anip
			
	
	return loadAnimation([delta_tag_name,animation_type,loops,fps,bone_names,modifiers,keys,notes],ret_name,skeleton,"",rests)
func load_animclip_from_path_with_rests(path:String,skeleton:Skeleton3D,animation_name:String,replace_existent_animations:bool,rests:Array) -> Animation:
	var f:FileAccess = FileAccess.open(path,FileAccess.READ)
	if !f:
		push_error("the file could not be readen.")
		return
	
	var delta_tag_name:String = ""
	
	var magic:String = f.get_buffer(6).get_string_from_ascii()
	if magic != "SEAnim": #not a SEAnim file
		push_error("The file " + f.get_path().get_file() + " was not a SEAnim file, so it was skipped.")
		return
		
		
	var version:int = f.get_16()
	var header_size:int = f.get_16()
	var animation_type:int = f.get_8()
	var flags:int = f.get_8()
	
	var loops:bool = (flags & (1 << 0)) != 0;
	var presence_flag:int = f.get_8()
	var property_flag:int = f.get_8()
	f.seek(f.get_position()+2)
	var fps:float = f.get_float()
	var frame_count:int = f.get_32()
	var bone_count:int = f.get_32()
	var mod_count:int = f.get_8()
	f.seek(f.get_position()+3)
	var note_count:int = f.get_32()
	var bone_names:Array = strings_read(bone_count,f)
	if animation_type == 3:
		if len(bone_names) > 0:
			delta_tag_name = bone_names[0]
			
	var modifiers:Array = []
	for i:int in range(0,mod_count):
		var index:int = (f.get_8() if bone_count <= 255 else f.get_16())
		modifiers.append([index,f.get_8()])
		
		
	var double_precision:bool = property_flag & (1 << 0)
	var keys:Array = []
	for i:String in bone_names:
		var bone_flags:int = f.get_8()
		if presence_flag & 1 << 0: #got position keyframes!
			var keyframe_count:int = read_max_val(f,frame_count)
			for k:int in range(0,keyframe_count):
				var keyframe:int = read_max_val(f,frame_count)
				var vector:Vector3 = Vector3.ZERO
				if double_precision:
					vector.x = f.get_double()
					vector.y = f.get_double()
					vector.z = f.get_double()
				else:
					vector.x = f.get_float()
					vector.y = f.get_float()
					vector.z = f.get_float()
				keys.append(["position",i,keyframe,vector])
		if presence_flag & 1 << 1: #got rotation keyframes!
			var keyframe_count:int = read_max_val(f,frame_count)
			for k:int in range(0,keyframe_count):
				var keyframe:int = read_max_val(f,frame_count)
				var quaternion:Quaternion = Quaternion.IDENTITY
				if double_precision:
					quaternion.x = f.get_double()
					quaternion.y = f.get_double()
					quaternion.z = f.get_double()
					quaternion.w = f.get_double()
				else:
					quaternion.x = f.get_float()
					quaternion.y = f.get_float()
					quaternion.z = f.get_float()
					quaternion.w = f.get_float()
				keys.append(["rotation",i,keyframe,quaternion])
		if presence_flag & 1 << 2: #got scale keyframes!
			var keyframe_count:int = read_max_val(f,frame_count)
			for k:int in range(0,keyframe_count):
				var keyframe:int = read_max_val(f,frame_count)
				var vector:Vector3 = Vector3.ONE
				if double_precision:
					vector.x = f.get_double()
					vector.y = f.get_double()
					vector.z = f.get_double()
				else:
					vector.x = f.get_float()
					vector.y = f.get_float()
					vector.z = f.get_float()
				keys.append(["scale",i,keyframe,vector])

	var notes:Array = []
	for i:int in range(0,note_count):
		var keyframe:int = read_max_val(f,frame_count)
		var note:Array = strings_read(1,f)
		notes.append([keyframe,note])
		
	var ret_name:String = animation_name
	if ret_name == "":
		ret_name = f.get_path().get_file().replace("." + f.get_path().get_extension(),"")
	if skeleton.get_node_or_null("SEPlayer") != null:
		var anip:AnimationPlayer = skeleton.get_node_or_null("SEPlayer")
		for n:String in anip.get_animation_library_list():
			var anib:AnimationLibrary = anip.get_animation_library(n)
			if ret_name in anib.get_animation_list():
				if !replace_existent_animations:
					return null
			
	
	return loadONLYAnimation([delta_tag_name,animation_type,loops,fps,bone_names,modifiers,keys,notes],ret_name,skeleton,rests)
	

func getRests(node:Skeleton3D) -> Array:
	node.reset_bone_poses() 
	var rests:Array = []
	for i:int in range(0,node.get_bone_count()):
		rests.append([node.get_bone_name(i),node.get_bone_pose_position(i)])
	return rests
	
func loadAnimation(data:Array,anim_name:String,node:Skeleton3D,prefix:String,rests:Array) -> AnimationPlayer:
	node.reset_bone_poses()
	var selNode:Node = node.get_tree().root
	
	var INFO:SEInfo = SEInfo.new()
	if node.get_node_or_null("SEInfo") == null:
		node.add_child(INFO)
		INFO.name = "SEInfo"
		INFO.owner = selNode
	else:
		INFO = node.get_node("SEInfo")
		
	

	if prefix.ends_with("_"):
		prefix = prefix.substr(0,len(prefix)-1)
	
	var anip:AnimationPlayer = AnimationPlayer.new()
	if node.get_node_or_null("SEPlayer") == null:
		node.add_child(anip)
		anip.owner = selNode
		anip.name = "SEPlayer"
	else:
		anip = node.get_node_or_null("SEPlayer")
	var animlib:AnimationLibrary = AnimationLibrary.new()
	
	
	if anip.has_animation_library(prefix) ==false:
		if prefix != "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT234u8956432u825u929u34t5w2":
			anip.add_animation_library(prefix, animlib)
		else:
			if anip.get_animation_library("Global") == null:
				anip.add_animation_library("Global", animlib)
			else:
				animlib = anip.get_animation_library("Global")
	else:
		animlib = anip.get_animation_library(prefix)
	
	
	var seanim:Animation = Animation.new()
	seanim.loop_mode = Animation.LOOP_NONE if data[2] == false && anim_name.contains("loop") != true else Animation.LOOP_LINEAR
	var last_frame:float = 0
	for i:Array in data[6]:
		if node.find_bone(i[1]) != -1:
			var track_path:String = ".:" + i[1]
			var track:int = 0
			var su_type:Animation.TrackType = Animation.TYPE_POSITION_3D
			
			if i[0] == "position":
				su_type = Animation.TYPE_POSITION_3D
			if i[0] == "rotation":
				su_type = Animation.TYPE_ROTATION_3D
			if i[0] == "scale":
				su_type = Animation.TYPE_SCALE_3D
			
			if seanim.find_track(track_path, su_type) == -1:
				track = seanim.add_track(su_type)
				seanim.track_set_path(track,track_path)
			else:
				track = seanim.find_track(track_path,su_type)
	


			var frame:float = i[2] / data[3]
			if i[0] == "position":
				for n:Array in rests:
					if n[0] == i[1]:
						seanim.track_insert_key(track,frame,n[1] + (i[3] / 100.0))
						break
			else:
				seanim.track_insert_key(track,frame,i[3])
				
				
				
			if last_frame < i[2] / data[3]:
				last_frame = i[2] / data[3]
			#["rotation",i,keyframe,quaternion]
	if len(data[7]) > 0: 
		var NOTE_TRACK:int = seanim.add_track(Animation.TYPE_METHOD)
		seanim.track_set_path(NOTE_TRACK,"SEInfo")
		
		for i:Array in data[7]:
			var method_dictionary:Dictionary = {
			"method": "NoteTrackData",
			"args": i[1],
		}
			seanim.track_insert_key(NOTE_TRACK,i[0] / data[3],method_dictionary)

	seanim.length = last_frame
	
	
	if animlib.has_animation(anim_name) == false:
		animlib.add_animation(anim_name, seanim)
	else:
		animlib.remove_animation(anim_name)
		animlib.add_animation(anim_name, seanim)
	return anip
func loadONLYAnimation(data:Array,anim_name:String,node:Skeleton3D,rests:Array) -> Animation:
	node.reset_bone_poses()
	var selNode:Node = node.get_tree().root
	
	var INFO:SEInfo = SEInfo.new()
	if node.get_node_or_null("SEInfo") == null:
		node.add_child(INFO)
		INFO.name = "SEInfo"
		INFO.owner = selNode
	else:
		INFO = node.get_node("SEInfo")

	var seanim:Animation = Animation.new()
	seanim.loop_mode = Animation.LOOP_NONE if data[2] == false && anim_name.contains("loop") != true else Animation.LOOP_LINEAR
	var last_frame:float = 0
	for i:Array in data[6]:
		if node.find_bone(i[1]) != -1:
			var track_path:String = ".:" + i[1]
			var track:int = 0
			var su_type:Animation.TrackType = Animation.TYPE_POSITION_3D
			
			if i[0] == "position":
				su_type = Animation.TYPE_POSITION_3D
			if i[0] == "rotation":
				su_type = Animation.TYPE_ROTATION_3D
			if i[0] == "scale":
				su_type = Animation.TYPE_SCALE_3D
			
			if seanim.find_track(track_path, su_type) == -1:
				track = seanim.add_track(su_type)
				seanim.track_set_path(track,track_path)
			else:
				track = seanim.find_track(track_path,su_type)
	


			var frame:float = i[2] / data[3]
			if i[0] == "position":
				for n:Array in rests:
					if n[0] == i[1]:
						seanim.track_insert_key(track,frame,n[1] + (i[3] / 100.0))
						break
			else:
				seanim.track_insert_key(track,frame,i[3])
				
				
				
			if last_frame < i[2] / data[3]:
				last_frame = i[2] / data[3]
			#["rotation",i,keyframe,quaternion]
	if len(data[7]) > 0: 
		var NOTE_TRACK:int = seanim.add_track(Animation.TYPE_METHOD)
		seanim.track_set_path(NOTE_TRACK,"SEInfo")
		
		for i:Array in data[7]:
			var method_dictionary:Dictionary = {
			"method": "NoteTrackData",
			"args": i[1],
		}
			seanim.track_insert_key(NOTE_TRACK,i[0] / data[3],method_dictionary)

	seanim.length = last_frame
	

	return seanim
func loadAnimationClip(data:Array,anim_name:String) -> Animation:
	var seanim:Animation = Animation.new()
	seanim.loop_mode = Animation.LOOP_NONE if data[2] == false && anim_name.contains("loop") != true else Animation.LOOP_LINEAR
	var last_frame:float = 0
	for i:Array in data[6]:
		var track_path:String = ".:" + i[1]
		var track:int = 0
		var su_type:Animation.TrackType = Animation.TYPE_POSITION_3D
		
		if i[0] == "position":
			su_type = Animation.TYPE_POSITION_3D
		if i[0] == "rotation":
			su_type = Animation.TYPE_ROTATION_3D
		if i[0] == "scale":
			su_type = Animation.TYPE_SCALE_3D
		
		if seanim.find_track(track_path, su_type) == -1:
			track = seanim.add_track(su_type)
			seanim.track_set_path(track,track_path)
		else:
			track = seanim.find_track(track_path,su_type)
	


		var frame:float = i[2] / data[3]
		if i[0] == "position":
			seanim.track_insert_key(track,frame,i[3] / 100.0)
		else:
			seanim.track_insert_key(track,frame,i[3])
			
			
			
		if last_frame < i[2] / data[3]:
			last_frame = i[2] / data[3]
			#["rotation",i,keyframe,quaternion]
	if len(data[7]) > 0: 
		var NOTE_TRACK:int = seanim.add_track(Animation.TYPE_METHOD)
		seanim.track_set_path(NOTE_TRACK,"SEInfo")
		
		for i:Array in data[7]:
			var method_dictionary:Dictionary = {
			"method": "NoteTrackData",
			"args": i[1],
			}
			seanim.track_insert_key(NOTE_TRACK,i[0] / data[3],method_dictionary)
	seanim.resource_name = anim_name
	seanim.length = last_frame
	return seanim
func traverse_skeleton(bone_array:PackedInt32Array,skeleton:Skeleton3D,index:int,include_first:bool) -> void:
	if include_first:
		bone_array.append(index)
	for i:int in skeleton.get_bone_children(index):
		traverse_skeleton(bone_array,skeleton,i,true)
func createModel(model:Array,callerNode:Node3D)-> Skeleton3D:
	var selNode:Node = callerNode.get_tree().root
	var root:Skeleton3D = Skeleton3D.new()
	
	
	callerNode.add_child(root)
	root.name = model[3].replace(".semodel","")
	root.owner = selNode
	

	for bname:int in range(0, len(model[0])):
		var cbone:int = root.add_bone(model[0][bname][0])
		root.set_bone_parent(bname,model[0][bname][1])
		

		
		root.set_bone_pose_position(bname, model[0][bname][3] / 100.0)
		root.set_bone_pose_rotation(bname, model[0][bname][5])
		root.set_bone_pose_scale(bname, model[0][bname][6])
		root.set_bone_rest(bname, root.get_bone_pose(cbone))
	var sk:Skin = root.create_skin_from_rest_transforms()
	apply_pose_as_rest_pose(root)
	#for bname in range(0, len(rests)):
	#	root.set_bone_rest(root.find_bone(bone_names[bname]), rests[bname])
		#root.set_bone_rest(bname,Transform3D.IDENTITY)
		
	#root.localize_rests()
	var allMat:Array = []
	for m:Array in model[2]:
		var mat:StandardMaterial3D = StandardMaterial3D.new()
		mat.resource_name = m[0]
		allMat.append(mat);
	
	
	var MAT:Script = load("res://addons/setools/sematerial.gd")
	
	for meshes:Array in model[1]:
		var mesh:MeshInstance3D = MeshInstance3D.new()
		mesh.set_script(MAT)
		var SEMAT:SEMaterial = mesh as SEMaterial
		var arraymesh:ArrayMesh = ArrayMesh.new()
		var uv_sets:Array[Vector2] = []
		SEMAT.materials = []
		var bone_indexes:Array = []
		var bone_weights:Array= []
		for v:int in range(0,len(meshes[0])):
			for n:Vector2 in meshes[0][v][1]:
				uv_sets.append(n)
				
			var BI:PackedInt32Array = []
			var BW:PackedFloat32Array = []
			if len(meshes[0][v][4]) <= 4:
				for n:Array in meshes[0][v][4]:
					BI.append(n[0])
					BW.append(n[1])
			else:
				meshes[0][v][4].sort_custom(func(a:Array, b:Array) -> bool:
					return b[1] <= a[1]
				)
				meshes[0][v][4] = meshes[0][v][4].slice(0, 4)
				var sum:float = 0
				for ne:Array in meshes[0][v][4]:
					sum += ne[1]
				for ne:Array in meshes[0][v][4]:
					BI.append(ne[0])
					BW.append(ne[1] / sum)
			bone_indexes.append(BI)
			bone_weights.append(BW)
		
		
		for vt:int in meshes[2]:
			for m:Array in model[2]:
				if m[0] == allMat[vt].resource_name:
					SEMAT.materials.append(["material: " + m[0], "albedo: " + m[1],"normal: " + m[2],"specular: " + m[3]])
					
					var surf:SurfaceTool = SurfaceTool.new()
					#surf.set_skin_weight_count(MAX_SKIN_WEIGHTS)
					surf.begin(Mesh.PRIMITIVE_TRIANGLES)
					surf.set_material(allMat[vt])
						
					for v:int in range(0,len(meshes[0])):
						surf.set_uv(uv_sets[v])
						surf.set_normal(meshes[0][v][2])
						surf.set_color(Color(meshes[0][v][3].x,meshes[0][v][3].y,meshes[0][v][3].z,meshes[0][v][3].w))
						surf.set_bones(bone_indexes[v])
						surf.set_weights(bone_weights[v])
						#surf.mat
						
						surf.add_vertex(meshes[0][v][0] / 100.0)
					for n:Vector3 in meshes[1]:
							surf.add_index(n.x)
							surf.add_index(n.y)
							surf.add_index(n.z)
					
					surf.commit(arraymesh)
					arraymesh.surface_set_name(arraymesh.get_surface_count()-1,m[0])
					
					
					
		root.add_child(mesh)
		mesh.owner = selNode
		mesh.name = "SEMesh0"
		
		mesh.mesh = arraymesh
		mesh.skeleton = mesh.get_path_to(root)
		mesh.skin = sk
	return root
func find_new_name(skeleton:Skeleton3D,bname:String) -> String:
	var fo:String = bname
	var fo_fin:String = fo
	var alli:int = 0
	while skeleton.find_bone(fo_fin) != -1:
		alli += 1
		fo_fin = fo + "_"+ str(alli)
	return fo_fin
func strings_read(count:int,f:FileAccess) -> Array:
	var names:Array = []
	for i:int in range(0,count):
		var finish:bool = false
		var retstring:String = ""
		while !finish:
			var cchar:PackedByteArray = f.get_buffer(1)
			if cchar[0] != 0:
				retstring += cchar.get_string_from_ascii()
			else:
				names.append(retstring)
				finish = true
				break
	return names
func strings_read_bytes(count:int,f:StreamPeerBuffer) -> Array:
	var names:Array = []
	for i:int in range(0,count):
		var finish:bool = false
		var retstring:String = ""
		while !finish:
			var cchar:PackedByteArray = f.get_data(1)
			if cchar[0] != 0:
				retstring += cchar.get_string_from_ascii()
			else:
				names.append(retstring)
				finish = true
				break
	return names
func read_single_string(f:FileAccess) -> String:
	var finish:bool = false
	var retstring:String = ""
	while !finish:
		var cchar:PackedByteArray = f.get_buffer(1)
		if cchar[0] != 0:
			retstring += cchar.get_string_from_ascii()
		else:
			finish = true
			break
	return retstring
func read_single_string_bytes(f:StreamPeerBuffer) -> String:
	var finish:bool = false
	var retstring:String = ""
	while !finish:
		var cchar:PackedByteArray = f.get_data(1)
		if cchar[0] != 0:
			retstring += cchar.get_string_from_ascii()
		else:
			finish = true
			break
	return retstring
func apply_pose_as_rest_pose(skeleton:Skeleton3D) -> void:
	if skeleton == null:
		push_error("Skeleton is not assigned.")
		return
	var bone_count:int = skeleton.get_bone_count()
	for i:int in range(0,bone_count):
		skeleton.set_bone_rest(i, skeleton.get_bone_pose(i))
func find_array_name(Arrays:Array, old_name:String) -> String:
	for n:Array in Arrays:
		if n[0] == old_name:
			return n[1]
	return ""
func get_common(strings: Array) -> String:
	if strings == null or strings.is_empty():
		return "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT234u8956432u825u929u34t5w2"

	var prefix: String = strings[0]

	for i:int in range(1, strings.size()):
		while not strings[i].begins_with(prefix):
			if prefix.length() == 0:
				return "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT234u8956432u825u929u34t5w2"
			prefix = prefix.substr(0, prefix.length() - 1)
			
	if prefix == strings[0]:
		return "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT234u8956432u825u929u34t5w2"
	return prefix
func get_tex_name(path:String) -> String:
	var spl:Array = path.split('\\')
	return spl[len(spl)-1]
func get_all_files(path: String,extensions:Array) -> Array:
	var files: Array = []
	var dir:DirAccess = DirAccess.open(path)
	if dir == null:
		push_error("Cannot open directory: %s" % path)
		return files
	_add_files_recursive(dir, path, files,extensions)
	return files
func _add_files_recursive(dir: DirAccess, path: String, files: Array, valid_exts: Array) -> void:
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			var sub_dir: DirAccess = DirAccess.open(full_path)
			if sub_dir:
				_add_files_recursive(sub_dir, full_path, files, valid_exts)
		else:
			var ext:String = full_path.get_extension().to_lower()
			if valid_exts.is_empty() or valid_exts.has(ext):
				files.append(full_path)
		
		file_name = dir.get_next()
	dir.list_dir_end()
func load_texture_from_path(path: String) -> ImageTexture:
	#print(path)
	var t:ImageTexture = ResourceLoader.load(path)
	t.resource_name  = path.get_file().replace("." + path.get_extension(),"")
	return t
func get_files_with_extension(dir_path: String, extension: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension().to_lower() == extension.to_lower():
				result.append(dir_path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Failed to open directory: %s" % dir_path)
	return result


func has_uv(mesh: Mesh) -> bool:
	if mesh == null:
		return false
	for surface in mesh.get_surface_count():
		var arrays = mesh.surface_get_arrays(surface)
		var uvs = arrays[Mesh.ARRAY_TEX_UV]
		if uvs and uvs.size() > 0:
			return true
	return false
func has_normal(mesh: Mesh) -> bool:
	if mesh == null:
		return false
	for surface in mesh.get_surface_count():
		var arrays = mesh.surface_get_arrays(surface)
		var normals = arrays[Mesh.ARRAY_NORMAL]
		if normals and normals.size() > 0:
			return true
	return false
func has_color(mesh: Mesh) -> bool:
	if mesh == null:
		return false
	for surface in mesh.get_surface_count():
		var arrays = mesh.surface_get_arrays(surface)
		var normals = arrays[Mesh.ARRAY_COLOR]
		if normals and normals.size() > 0:
			return true
	return false
func has_weight(mesh: Mesh) -> bool:
	if mesh == null:
		return false
	for surface in mesh.get_surface_count():
		var arrays = mesh.surface_get_arrays(surface)
		var normals = arrays[Mesh.ARRAY_WEIGHTS]
		if normals and normals.size() > 0:
			return true
	return false
func get_all_materials(mesh_instance: MeshInstance3D) -> Array:
	var materials: Array = []
	var mesh: Mesh = mesh_instance.mesh

	if mesh == null:
		return materials

	for surface in mesh.get_surface_count():
		# Check for override material first
		var material = mesh_instance.get_surface_override_material(surface)
		if material == null:
			# Fall back to the material from the mesh itself
			material = mesh.surface_get_material(surface)

		materials.append(material)
	
	return materials
func get_all_verts(mesh: ArrayMesh) -> Array:
	var all_verts: Array = []
	for surface in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface)
		var verts = arrays[Mesh.ARRAY_VERTEX]
		if verts:
			all_verts.append_array(verts)
	return all_verts
func get_all_faces(mesh: ArrayMesh) -> Array:
	var all_faces: Array = []
	for surface in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface)
		var indices = arrays[Mesh.ARRAY_INDEX]
		if indices:
			all_faces.append_array(indices)
	return all_faces
func get_all_uvs(mesh: ArrayMesh) -> Array:
	var all_uvs: Array = []
	for surface in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface)
		var uvs = arrays[Mesh.ARRAY_TEX_UV]
		if uvs:
			all_uvs.append_array(uvs)
	return all_uvs
func get_all_normals(mesh: ArrayMesh) -> Array:
	var all_normals: Array = []
	for surface in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface)
		var normals = arrays[Mesh.ARRAY_NORMAL]
		if normals:
			all_normals.append_array(normals)
	return all_normals
func get_all_colors(mesh: ArrayMesh) -> Array:
	var all_colors: Array = []
	for surface in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface)
		var colors = arrays[Mesh.ARRAY_COLOR]
		if colors:
			all_colors.append_array(colors)
	return all_colors
func get_all_weights(mesh: ArrayMesh) -> Array:
	var all_weights: Array = []
	for surface in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface)
		var weights = arrays[Mesh.ARRAY_WEIGHTS]
		if weights:
			all_weights.append_array(weights)
	return all_weights
func get_all_weight_indices(mesh: ArrayMesh) -> Array:
	var all_bones: Array = []
	for surface in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface)
		var bones = arrays[Mesh.ARRAY_BONES]
		if bones:
			all_bones.append_array(bones)
	return all_bones
func get_mesh_format(mesh: ArrayMesh) -> bool:
	var USE_4: bool = true
	for surface in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface)
		var flags = mesh.surface_get_format(surface)
		if flags & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS != 0:
			USE_4 = false
	return USE_4
func transfer_vertex_positions(og_mesh: ArrayMesh, sup_mesh: ArrayMesh):
	for surface in range(og_mesh.get_surface_count()):
		var og_arrays = og_mesh.surface_get_arrays(surface)
		var sup_arrays = sup_mesh.surface_get_arrays(surface)
		og_arrays[Mesh.ARRAY_VERTEX] = sup_arrays[Mesh.ARRAY_VERTEX]
		og_mesh.surface_update_attribute_region(surface, Mesh.ARRAY_VERTEX, og_arrays[Mesh.ARRAY_VERTEX])
