@tool

extends Control

@onready var IO:FileDialog = $IO
@onready var IO2:FileDialog = $IO2
var tool_plugin:Node
@onready var merect:TextureRect = $MMB/CR

func activate_merge() -> void:
	merect.visible = true
func disable_merge() -> void:
	merect.visible = false
	
	
	
func IISEMO() -> void:
	if IO.files_selected.is_connected(loadSEAnim):
		IO.files_selected.disconnect(loadSEAnim)
		IO.files_selected.connect(loadSEModel)
		
	if IO.files_selected.is_connected(loadSEModel):
		IO.files_selected.disconnect(loadSEModel)
		
	IO.files_selected.connect(loadSEModel)
		
		
	
	IO.access = FileDialog.ACCESS_FILESYSTEM
	IO.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	IO.filters = ["*.semodel"]
	IO.popup()
func loadSEModel(paths:PackedStringArray)->void:
	IO.files_selected.disconnect(loadSEModel)
	for path:String in paths:
		var f:FileAccess = FileAccess.open(path, FileAccess.READ)
		if f:
			createModel(LMOP(f))
		else:
			push_error("Failed to open file: %s" % f)
func LMOP(f:FileAccess) -> Array:
	var magic:String = f.get_buffer(7).get_string_from_ascii()
	if magic != "SEModel": #not a SEMODEL file
		push_warning("The file " + f.get_path().get_file() + " was not a SEModel file, so it was skipped.")
		return []
	
	var version:int = f.get_16()
	var header_size:int = f.get_16()
	
	
	var data_presence_flags:int = f.get_8()
	var bone_data_presence_flags:int = f.get_8()
	var mesh_data_presence_flags:int = f.get_8()
	
	
	
	var bone_count:int = f.get_32()
	var mesh_count:int = f.get_32()
	var mate_count:int = f.get_32()
	print(bone_count)
	f.seek(f.get_position() + 3)

	var bone_names:PackedStringArray
	bone_names.append_array(SE.SEU.strings_read(bone_count,f)) #read the bone names
	
		
	var bone_data:Array = []
	for i:int in range(0,bone_count): #this one will start reading the bones data
		var bone_flags:int = f.get_8()
		var bone_parent_index:int = f.get_32()
		
		var g_position:Vector3 = Vector3.ZERO
		var l_position:Vector3 = Vector3.ZERO
		var g_rotation:Quaternion = Quaternion.IDENTITY
		var l_rotation:Quaternion = Quaternion.IDENTITY
		var l_scale:Vector3 = Vector3.ONE

		if bone_data_presence_flags & 1 << 0: #if the flag checks for the global matrix
			g_position = Vector3(f.get_float(),f.get_float(),f.get_float());
			g_rotation = Quaternion(f.get_float(),f.get_float(),f.get_float(),f.get_float());
		if bone_data_presence_flags & 1 << 1: #if the flag checks for the local matrix
			l_position = Vector3(f.get_float(),f.get_float(),f.get_float());
			l_rotation = Quaternion(f.get_float(),f.get_float(),f.get_float(),f.get_float());
		if bone_data_presence_flags & 1 << 2: #if the flag checks for the scale
			l_scale = Vector3(f.get_float(),f.get_float(),f.get_float());
		bone_data.append([bone_names[i],bone_parent_index,g_position,l_position,g_rotation,l_rotation,l_scale])
		#print(f.get_position())
	
	
	var meshes:Array = []
	var materials:Array = []
	
	for i:int in range(0,mesh_count):
		var mesh_flags:int = f.get_8()
		var mate_indices_count:int = f.get_8()
		var max_skin_influences_count:int = f.get_8()
		var vert_count:int = f.get_32()
		var tria_count:int = f.get_32()
		#print("MESH ", vert_count, "     ", mate_indices_count)
		#print(max_skin_influences_count)
		var vertices:Array = []
		var triangles:Array = []
		var material_index:Array = []

		for n:int in range(0,vert_count):
			vertices.append([Vector3(f.get_float(),f.get_float(),f.get_float()),[],Vector3(0,0,0),Vector4(1,1,1,1),[]])

		if mesh_data_presence_flags & 1 << 0: #if it is positive for uv
			for n:int in range(0,vert_count):
				for c:int in range(0,mate_indices_count):
					vertices[n][1].append(Vector2(f.get_float(),f.get_float()))
		if mesh_data_presence_flags & 1 << 1: #if it is positive for normals
			for n:int in range(0,vert_count):
				vertices[n][2] = Vector3(f.get_float(),f.get_float(),f.get_float())
		#print(f.get_position())
		if mesh_data_presence_flags & 1 << 2: #if it is positive for vert colors
			for n:int in range(0,vert_count):
				vertices[n][3] = Vector4(f.get_8() / 255.0,f.get_8() / 255.0,f.get_8() / 255.0,f.get_8() / 255.0)
		#print("BONE WEIGHTS PART ", f.get_position())
		if mesh_data_presence_flags & 1 << 3: #if it is positive for bone weights
			for n:int in range(0,vert_count):
				for e:int in range(0,max_skin_influences_count):
					if bone_count <= 255:
						vertices[n][4].append([f.get_8(),f.get_float()])
					elif bone_count <= 65535:
						vertices[n][4].append([f.get_16(),f.get_float()])
					else:
						vertices[n][4].append([f.get_32(),f.get_float()])
		#print(f.get_position())
		for n:int in range(0,tria_count):
			if vert_count <= 255:
				triangles.append(Vector3(f.get_8(),f.get_8(),f.get_8()))
			elif vert_count <= 65535:
				triangles.append(Vector3(f.get_16(),f.get_16(),f.get_16()))
			else:
				triangles.append(Vector3(f.get_32(),f.get_32(),f.get_32()))
		for n:int in range(0,mate_indices_count):
			material_index.append(f.get_32());
			
		#print("MESH ", len(vertices))
		#print(f.get_position())
		meshes.append([vertices,triangles,material_index])
		
		
	for n:int in range(0,mate_count):
		#print("MAT   ", f.get_position())
		var mate_name:String = SE.SEU.read_single_string(f)
		var diff_name:String = "Not informed"
		var norm_name:String = "Not informed"
		var spec_name:String = "Not informed"

		var simple:bool = f.get_8() == 1
		if simple:
			diff_name = SE.SEU.read_single_string(f) #diffuse
			norm_name = SE.SEU.read_single_string(f) #normal
			spec_name = SE.SEU.read_single_string(f) #specular
		#else:
		#	f.get_8()
		materials.append([mate_name,diff_name,norm_name,spec_name])
	var blend:String = SE.SEU.read_single_string(f)
	
	return [bone_data,meshes,materials,f.get_path().get_file()]
func createModel(model:Array)->void:
	var selNode:Node = get_tree().edited_scene_root
	var root:Skeleton3D = Skeleton3D.new()
	
	
	selNode.add_child(root)
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
	SE.SEU.apply_pose_as_rest_pose(root)
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
		SEMAT.materials = []
		
		var arraymesh:ArrayMesh = ArrayMesh.new()
		var uv_sets:Array[Vector2] = []
		
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
		#meshes[0] verts
func IISEAN() -> void:
	var sel_nodes:Array = tool_plugin.get_selected_nodes()
	if sel_nodes == []:
		push_error("ERROR: No armature was selected.")
		return
		
		
	
	if IO.files_selected.is_connected(loadSEModel):
		IO.files_selected.disconnect(loadSEModel)
		IO.files_selected.connect(loadSEAnim)
		
	if IO.files_selected.is_connected(loadSEAnim):
		IO.files_selected.disconnect(loadSEAnim)
		
	IO.files_selected.connect(loadSEAnim)
	
	
	
	
	IO.access = FileDialog.ACCESS_FILESYSTEM
	IO.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	IO.filters = ["*.seanim"]
	IO.popup()
func loadSEAnim(paths:PackedStringArray)->void:
	IO.files_selected.disconnect(loadSEAnim)
	var sel_nodes:Array = tool_plugin.get_selected_nodes()
	if sel_nodes == []:
		push_error("ERROR: No armature was selected.")
		return
	var sel_node:Skeleton3D = sel_nodes[0]
	
	var names:PackedStringArray = []
	for n:String in paths:
		names.append(n.get_file().replace("." + n.get_extension(),""))
	var prefix:String = SE.SEU.get_common(names)
	
	sel_node.reset_bone_poses()
	var ownerNode:Node = get_tree().edited_scene_root
	var rests:Dictionary = {}
	var bnames:Dictionary = {}
	for i:int in range(0,sel_node.get_bone_count()):
		rests[sel_node.get_bone_name(i)] = sel_node.get_bone_pose_position(i)
		bnames[sel_node.get_bone_name(i)] = true
	
	var file_name:String = ""
	var clean_name:String = ""
	
	
	
	var INFO:SEInfo = SEInfo.new()
	if sel_node.get_node_or_null("SEInfo") == null:
		sel_node.add_child(INFO)
		INFO.name = "SEInfo"
		INFO.owner = ownerNode
	else:
		INFO = sel_node.get_node("SEInfo")
		

	if prefix.ends_with("_"):
		prefix = prefix.substr(0,len(prefix)-1)
	var anip:AnimationPlayer = AnimationPlayer.new()
	if sel_node.get_node_or_null("SEPlayer") == null:
		sel_node.add_child(anip)
		anip.owner = ownerNode
		anip.name = "SEPlayer"
	else:
		anip = sel_node.get_node_or_null("SEPlayer")
	var animlib:AnimationLibrary = AnimationLibrary.new()
	
	if anip.has_animation_library(prefix) == false:
		if prefix != "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT234u8956432u825u929u34t5w2":
			anip.add_animation_library(prefix, animlib)
		else:
			if anip.has_animation_library("Global") == false:
				anip.add_animation_library("Global", animlib)
			else:
				animlib = anip.get_animation_library("Global")
	else:
		animlib = anip.get_animation_library(prefix)
	
	
	
	
	
	
	
	for path:String in paths:
		var f:FileAccess = FileAccess.open(path, FileAccess.READ)
		file_name = path.get_file()
		clean_name = file_name.replace("." + path.get_extension(), "").replace(prefix,"")
		
		if f:
			var anim:Animation = LAOP(f, rests)
			f.close()
			#loadAnimation(LAOP(f), clean_name,sel_node,prefix,selNode,bnames,rests)
			
			if anim != null:
				#if animlib.has_animation(clean_name) == false:
					animlib.add_animation(clean_name, anim)
				#else:
				#	animlib.remove_animation(clean_name)
				#	animlib.add_animation(clean_name, anim)
		else:
			push_error("Failed to open file: %s" % path)
func LAOP(f:FileAccess, restPoses:Dictionary) -> Animation:
	var delta_tag_name:String = ""
	
	var magic:String = f.get_buffer(6).get_string_from_ascii()
	if magic != "SEAnim": #not a SEAnim file
		push_warning("The file " + f.get_path().get_file() + " was not a SEAnim file, so it was skipped.")
		return null
		
		
	var version:int = f.get_16()
	var header_size:int = f.get_16()
	var animation_type:int = f.get_8()
	var flags:int = f.get_8()
	
	var loops:bool = (flags & (1 << 0)) != 0
	var presence_flag:int = f.get_8()
	var property_flag:int = f.get_8()
	f.seek(f.get_position()+2)
	var fps:float = f.get_float()
	var frame_count:int = f.get_32()
	var bone_count:int = f.get_32()
	var mod_count:int = f.get_32()
	var note_count:int = f.get_32()
	var bone_names:Array = SE.SEU.strings_read(bone_count,f)

	#if animation_type == 3: this wasn't implemented, thought it wasn't needed.
	#	if len(bone_names) > 0:
	#		delta_tag_name = bone_names[0]
	
	
	var modifiers:Array = []
	#for i:int in range(0,mod_count): this wasn't implemented, thought it wasn't needed.
	#	var index:int = (f.get_8() if bone_count <= 255 else f.get_16())
	#	modifiers.append([index,f.get_8()])
		

	var double_precision:bool = property_flag & (1 << 0)
	
	
	
	
	var seanim:Animation = Animation.new()
	seanim.loop_mode = Animation.LOOP_NONE if loops else Animation.LOOP_LINEAR
	seanim.length = frame_count / fps
	
	
	var vector:Vector3 = Vector3.ZERO
	var quaternion:Quaternion = Quaternion.IDENTITY
	var frame:float = 0
	for i:String in bone_names:
		var bone_flags:int = f.get_8() #the only supported flags are DEFAULT (0) / COSMETIC (1)
		var track_path:String = ".:" + i
		var track:int = 0
		
		if presence_flag & 1 << 0: #got position keyframes!
			
			
			var keyframe_count:int = SE.SEU.read_max_val(f,frame_count)
			if keyframe_count > 0:
				var rest:Vector3 = restPoses.get(i, Vector3.ZERO)
				track = seanim.add_track(Animation.TrackType.TYPE_POSITION_3D)
				seanim.track_set_path(track,track_path)
			
				for k:int in range(0,keyframe_count):
					var keyframe:int = SE.SEU.read_max_val(f,frame_count)
					frame = keyframe / fps
					if double_precision:
						vector.x = f.get_double()
						vector.y = f.get_double()
						vector.z = f.get_double()
					else:
						vector.x = f.get_float()
						vector.y = f.get_float()
						vector.z = f.get_float()
					
					seanim.position_track_insert_key(track,frame,rest + (vector / 100.0))
					
				
		if presence_flag & 1 << 1: #got rotation keyframes!
			var keyframe_count:int = SE.SEU.read_max_val(f,frame_count)
			if keyframe_count > 0:
				track = seanim.add_track(Animation.TrackType.TYPE_ROTATION_3D)
				seanim.track_set_path(track,track_path)
				for k:int in range(0,keyframe_count):
					var keyframe:int = SE.SEU.read_max_val(f,frame_count)
					frame = keyframe / fps
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
					seanim.rotation_track_insert_key(track,frame,quaternion)
				
		if presence_flag & 1 << 2: #got scale keyframes!
			var keyframe_count:int = SE.SEU.read_max_val(f,frame_count)
			if keyframe_count > 0:
				track = seanim.add_track(Animation.TrackType.TYPE_SCALE_3D)
				seanim.track_set_path(track,track_path)
				for k:int in range(0,keyframe_count):
					var keyframe:int = SE.SEU.read_max_val(f,frame_count)
					frame = keyframe / fps
					if double_precision:
						vector.x = f.get_double()
						vector.y = f.get_double()
						vector.z = f.get_double()
					else:
						vector.x = f.get_float()
						vector.y = f.get_float()
						vector.z = f.get_float()
					seanim.scale_track_insert_key(track,frame,vector)

	
	
	if note_count > 0:
		var NOTE_TRACK:int = seanim.add_track(Animation.TYPE_METHOD)
		seanim.track_set_path(NOTE_TRACK,"SEInfo")
		

			
		for i:int in range(0,note_count):
			var keyframe:int = SE.SEU.read_max_val(f,frame_count)
			var note:Array = SE.SEU.strings_read(1,f)
			
			var method_dictionary:Dictionary = {
			"method": "NoteTrackData",
			"args": note,
			}
			frame = keyframe / fps
			seanim.track_insert_key(NOTE_TRACK, frame ,method_dictionary)
			

	
	return seanim

func LTCD() -> void:
	IO2.popup()
func LTCD_SEL(dir_path: String) -> void:
	var sel_nodes:Array = tool_plugin.get_selected_nodes()
	if sel_nodes == []:
		push_error("ERROR: No armature was selected.")
		return
	var skeleton:Skeleton3D = sel_nodes[0]
	var all_textures:Array = SE.SEU.get_all_files(dir_path, ["dds","ktx","ktx2","png","jpg","jpeg","bmp","tga"])
	
	
	var childs:Array[Node] = skeleton.get_children()
	for i:Node in childs:
		if i as MeshInstance3D != null:
			if i as SEMaterial != null:
				var mesh:MeshInstance3D = i as MeshInstance3D
				var mat:SEMaterial = i as SEMaterial
				
				
				
				for e:int in mesh.mesh.get_surface_count():
					var mat_name:String = SE.SEU.get_tex_name(mat.materials[e][0].split(': ')[1])
					var albedo_name:String = SE.SEU.get_tex_name(mat.materials[e][1].split(': ')[1])
					var normal_name:String = SE.SEU.get_tex_name(mat.materials[e][2].split(': ')[1])
					var specular_name:String = SE.SEU.get_tex_name(mat.materials[e][3].split(': ')[1])
					#for file:String in all_textures:
						
					var MAT:StandardMaterial3D = mesh.mesh.surface_get_material(e)
					for t:String in all_textures:
						if albedo_name in t:
							MAT.albedo_texture = SE.SEU.load_texture_from_path(t)
						if normal_name in t:
							MAT.normal_enabled = true
							MAT.normal_texture = SE.SEU.load_texture_from_path(t)
						if specular_name in t:
							MAT.metallic_texture = SE.SEU.load_texture_from_path(t)
							
					#print(MAT.resource_name)
func EESEMO() -> void:
	var sel_nodes:Array = tool_plugin.get_selected_nodes()
	if sel_nodes == []:
		push_error("ERROR: No armature was selected.")
		return
	var skeleton:Skeleton3D = sel_nodes[0]
	#print(skeleton)
	CSK = skeleton
	IO.file_selected.connect(SMOP)
		
		
	#print(IO.file_selected.get_connections())
	IO.access = FileDialog.ACCESS_FILESYSTEM
	IO.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	IO.filters = ["*.semodel"]
	IO.popup()
func EESEANI() -> void:
	var sel_nodes:Array = tool_plugin.get_selected_animation_player()
	if sel_nodes == []:
		push_error("ERROR: No AnimationPlayer was selected.")
		return
	IO.dir_selected.connect(SAOP.bind(sel_nodes[0]))
		
		
	#print(IO.file_selected.get_connections())
	IO.access = FileDialog.ACCESS_FILESYSTEM
	IO.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	IO.filters = ["*.seanim"]
	IO.popup()
var CSK:Skeleton3D
func SAOP(CPATH:String, CAP:AnimationPlayer,bakeFPS:float = 60, speedScale:float = 1):
	IO.dir_selected.disconnect(SAOP)
	var skeleton:Skeleton3D = CAP.get_node_or_null(CAP.root_node)
	if skeleton == null:
		push_error("ERROR: Selected AnimationPlayer's root node is not a skeleton or doesn't exist.")
		return
		
	skeleton.reset_bone_poses()
	var rests:Dictionary = {}
	for i:int in range(0,skeleton.get_bone_count()):
		var bone_name:String = skeleton.get_bone_name(i)
		rests[bone_name] = skeleton.get_bone_pose_position(i)
	#storing the rest is essential cuz godot calculate positions as absolute and not relative
		
		
	for lib:String in CAP.get_animation_library_list():
		var library:AnimationLibrary = CAP.get_animation_library(lib)
		if !library:
			continue
		for animation:String in library.get_animation_list():
			var anim:Animation = library.get_animation(animation)
			if !anim:
				push_error("ERROR: Animation " + animation + " isn't valid or wasn't found.")
				continue
			var f:FileAccess = FileAccess.open(CPATH + "/" + animation + ".seanim",FileAccess.WRITE)
			if !f:
				push_error("ERROR: Animation file for " + animation + " could not be created.")
			
			var animLength:float = 0
			for i:int in anim.get_track_count(): #this check is absolutely needed, since in some cases the animation length is not the same as the max keyframe length, this would result on a messy resampling.
				for key:int in anim.track_get_key_count(i):
					var time:float = anim.track_get_key_time(i,key) * speedScale
					if time > animLength:
						animLength = time
					
			var step:float = 1.0 / bakeFPS
			var dataDict:Dictionary = {} #thought i were going to name it datadic? LMFAO
			var noteArray:Array[Array] = []
			var POS:bool = false
			var ROT:bool = false
			var SCA:bool = false
			var frame_count:int = 0 #animation lenght in frames
			#for i:int in anim.track_swap()
			for i:int in anim.get_track_count():
				var t:int = anim.track_get_type(i)
				if !POS:
					POS = t == Animation.TYPE_POSITION_3D
				if !ROT:
					ROT = t == Animation.TYPE_ROTATION_3D
				if !SCA:
					SCA = t == Animation.TYPE_SCALE_3D
			for i:int in anim.get_track_count():
				var t:int = anim.track_get_type(i)

				var track:NodePath = anim.track_get_path(i)
				var node:Node = skeleton.get_node_or_null(track)
				if !node:
					continue
				if node == skeleton:
					var bone_name:String = track.get_subname(0)
					
					#print(bone_name)
					var data:Array[Array] = [[]]
					data.append([])
					data.append([])
					data.append([])
					var countPos:int = 0
					var countRot:int = 0
					var countSca:int = 0
					
					
					for key:int in anim.track_get_key_count(i):
						var time:float = anim.track_get_key_time(i,key) * speedScale
						var kIndex:int = round(time / step)
						if kIndex > frame_count:
							frame_count = kIndex
						var value = anim.track_get_key_value(i,key)
						if t == Animation.TYPE_POSITION_3D:
							countPos += 1
							data[0].append([kIndex,(value - rests[bone_name]) * 100])
									
						if t == Animation.TYPE_ROTATION_3D:
							countRot += 1
							data[1].append([kIndex,value])
							
						if t == Animation.TYPE_SCALE_3D:
							countSca += 1
							data[2].append([kIndex,value])
							
						#print(kIndex, "    ", animation)
						#print(cTime * bakeFPS)
						
					if !dataDict.has(bone_name):
						dataDict[bone_name] = [
							countPos,
							countRot,
							countSca,
							data]
					else:
						var vt:Array = dataDict[bone_name]
						if t == Animation.TYPE_POSITION_3D:
							vt[0] = countPos
							vt[3][0] = data[0]
						if t == Animation.TYPE_ROTATION_3D:
							vt[1] = countRot
							vt[3][1] = data[1]
						if t == Animation.TYPE_SCALE_3D:
							vt[2] = countSca
							vt[3][2] = data[2]
							
				else:
					if node as SEInfo != null:
						for key:int in anim.track_get_key_count(i):
							var time:float = anim.track_get_key_time(i,key) * speedScale
							var kIndex:int = round(time / step)
							if kIndex > frame_count:
								frame_count = kIndex
							var value = anim.track_get_key_value(i,key)
							for v:int in range(value.args.size()):
								if value.args[v] is String:
									noteArray.append([kIndex, value.args[v]])
						
				
			
			noteArray.sort_custom(func(a,b) -> bool: return a[0] < b[0])
			
			f.store_buffer("SEAnim".to_ascii_buffer())
			f.store_16(1) #version
			f.store_16(28)
			
			var animType:int = 2 #absolute, additive and delta wasn't implemented, due to it being very underused. These calculations are usually handled by engines.
			f.store_8(animType)
			var animFlags:int = 0
			animFlags = animFlags | ((1 if anim.loop_mode == Animation.LoopMode.LOOP_LINEAR else 0) << 0) #looped
			f.store_8(animFlags)
			
			
			var presenceFlags:int = 0
			
			presenceFlags |= ((1 if POS else 0) << 0)
			presenceFlags |= ((1 if ROT else 0) << 1)
			presenceFlags |= ((1 if SCA else 0) << 2)
			
			# bits 3,4,5 are already 0 → no need to set them
			
			presenceFlags |= ((1 if (noteArray.size() > 0) else 0) << 6) # notetrack
			presenceFlags |= (0 << 7)
			
			f.store_8(presenceFlags)
			
			var dataFlags:int = 0
			dataFlags |= (0 << 0) #this flags tells if this animation uses doubles on coordinates or floats. Since godot natively DONT support animation coordinate calculation on doubles, implementing this would be pointless.
			f.store_8(dataFlags)
			
			
			
			f.store_16(0)
			f.store_float(bakeFPS)
			f.store_32(frame_count) #lenght of the animation in frames
			f.store_32(dataDict.keys().size()) #amount of animated bones
			f.store_32(0) #my implementation does not support animation modifiers

			f.store_32(noteArray.size())
			for i:String in dataDict.keys():
				f.store_buffer(i.to_ascii_buffer())
				f.store_8(0)
				
				
			for i:String in dataDict.keys():
				var bone_flags:int = 0
				#bone_flags |= ((1 if dataDict[i][0] else 0) << 0)
				#bone_flags |= ((1 if dataDict[i][1] else 0) << 1)
				#bone_flags |= ((1 if dataDict[i][2] else 0) << 2)
				f.store_8(bone_flags)
				if POS:
					SE.SEU.store_max_val(f, frame_count, dataDict[i][0])
					for dat in dataDict[i][3][0]:
						SE.SEU.store_max_val(f, frame_count, dat[0])
						f.store_float(dat[1].x)
						f.store_float(dat[1].y)
						f.store_float(dat[1].z)
				if ROT:
					SE.SEU.store_max_val(f, frame_count, dataDict[i][1])
					for dat in dataDict[i][3][1]:
						SE.SEU.store_max_val(f, frame_count, dat[0])
						f.store_float(dat[1].x)
						f.store_float(dat[1].y)
						f.store_float(dat[1].z)
						f.store_float(dat[1].w)
				if SCA:
					SE.SEU.store_max_val(f, frame_count, dataDict[i][2])
					for dat in dataDict[i][3][2]:
						SE.SEU.store_max_val(f, frame_count, dat[0])
						f.store_float(dat[1].x)
						f.store_float(dat[1].y)
						f.store_float(dat[1].z)
			for i:Array in noteArray:
				#ULT.store_max_val(f, frame_count, i)
					SE.SEU.store_max_val(f, frame_count, i[0])
					f.store_buffer(i[1].to_ascii_buffer())
					f.store_8(0)
					#for sd in a[1]:
					#	f.store_buffer(sd.to_ascii_buffer())
					#	f.store_8(0)
			#f.store_buffer("SEBlend".to_ascii_buffer()) i don't know how this is implemented
			#f.store_64(0)
			#f.store_8(0)
				
		


	#for i:int in range(0,note_count):
	#	var keyframe:int = SEU.read_max_val(f,frame_count)
	#	var note:Array = SEU.strings_read(1,f)
	#	notes.append([keyframe,note])

	
func SMOP(CPATH:String):
	#print(path)
	IO.file_selected.disconnect(SMOP)
	#CSK.reset_bone_poses()
	var f:FileAccess = FileAccess.open(CPATH,FileAccess.WRITE)
	#var f2:FileAccess = FileAccess.open(CPATH+".txt",FileAccess.WRITE)
	if !f:
		push_error("ERROR: Could not create file.")
		return
	
	f.store_32(1867334995)
	f.store_16(25956)
	f.store_8(108)
	f.store_16(1) #version
	f.store_16(20) #header size
	var meshes:Array[MeshInstance3D] = []
	var semat:Array[StandardMaterial3D]
	var normal_check:bool = true
	var color_check:bool = true
	var weight_check:bool = true
	
	for an in CSK.get_children():
		if an is MeshInstance3D:
			var result_uv:bool = SE.SEU.has_uv(an.mesh)
			var result_no:bool = SE.SEU.has_normal(an.mesh)
			var result_we:bool = SE.SEU.has_weight(an.mesh)
			var result_co:bool = SE.SEU.has_color(an.mesh)
			#print(an.name)
			#print(result)
			if result_uv:
				meshes.append(an)
				
				if !result_no && normal_check:
					normal_check = false
					
				if !result_co && color_check:
					color_check = false
					
				if !result_we && weight_check:
					weight_check = false
			#print(an.get_path())
			if !result_uv || !result_no:
				push_warning("WARNING: The mesh " + an.name +" will not be exported with the file due to the following errors:")
				if !result_uv:
					print("* UVs not found.")
				if !result_no:
					print("* Normals not found.")
				#push_warning("WARNING: The mesh's UV from the mesh " + str(an.name) + " could not be computed. It will not be exported with the semodel. Check if the mesh(if exists) got any UVs.")
	

	for i in meshes:
		var cd_mat:Array = SE.SEU.get_all_materials(i)
		for t in cd_mat:
			if t not in semat:
				semat.append(t)
		#if i is SEMaterial:
		#	#print(i.materials)
		#	if len(i.materials) > 0:
		#		for n in i.materials:
		#			if len(n) == 4:
		#				semat.append(i)
		#				var g:String = n[1]

						#print(n[0].substr(10,-1), "     ",n[1].substr(8,64))
						#print("added")
			
	#for i in semat:
	#	print(i.resource_name)
	
	var dpf:int = 0
	dpf |= 1 << 0 if CSK.get_bone_count() > 0 else 0
	dpf |= 1 << 1 if len(meshes) > 0 else 0
	dpf |= 1 << 2 if len(semat) > 0 else 0
	f.store_8(dpf)
	

	f.store_8(7 if CSK.get_bone_count() > 0 else 0) #7 sets the presence of scale, local, and global as true.
	
	var mpf:int = 0
	mpf |= 1<<0
	mpf |= 1<<1 if normal_check else 0
	mpf |= 1<<2 if color_check else 0
	mpf |= 1<<3 if weight_check else 0
	f.store_8(mpf)
	f.store_32(CSK.get_bone_count())
	f.store_32(meshes.size())
	f.store_32(semat.size())
	f.store_16(0)
	f.store_8(0)
	for i in CSK.get_bone_count():
		f.store_string(CSK.get_bone_name(i))
		f.store_8(0)
	for i in CSK.get_bone_count():
		f.store_8(0)
		f.store_32(CSK.get_bone_parent(i))
		
		#var GLOBAL:Transform3D = CSK.get_bone_global_pose_override(i)
		var GLOBAL:Transform3D = CSK.get_bone_global_pose(i)
		var LPOS:Vector3 = CSK.get_bone_pose_position(i)
		var LROT:Quaternion = CSK.get_bone_pose_rotation(i)
		var LSCA:Vector3 = CSK.get_bone_pose_scale(i)
		
		f.store_float(GLOBAL.origin.x*100)
		f.store_float(GLOBAL.origin.y*100)
		f.store_float(GLOBAL.origin.z*100)
		
		f.store_float(GLOBAL.basis.get_rotation_quaternion().x)
		f.store_float(GLOBAL.basis.get_rotation_quaternion().y)
		f.store_float(GLOBAL.basis.get_rotation_quaternion().z)
		f.store_float(GLOBAL.basis.get_rotation_quaternion().w)
		
		
		f.store_float(LPOS.x*100)
		f.store_float(LPOS.y*100)
		f.store_float(LPOS.z*100)
		
		
		f.store_float(LROT.x)
		f.store_float(LROT.y)
		f.store_float(LROT.z)
		f.store_float(LROT.w)
		
		f.store_float(LSCA.x)
		f.store_float(LSCA.y)
		f.store_float(LSCA.z)
	
	var skin:Skin = Skin.new()
	
	for i in len(meshes):
		var ref_mesh:ArrayMesh = meshes[i].mesh

		
		f.store_8(0)
		var mats:Array = SE.SEU.get_all_materials(meshes[i])
		f.store_8(len(mats))
		var skin4mode:bool = SE.SEU.get_mesh_format(ref_mesh)
		f.store_8(4 if skin4mode else 8)
		var vertices:PackedVector3Array = SE.SEU.get_all_verts(ref_mesh)
		if meshes[i].skin:
			vertices = []
			var sup_mesh:ArrayMesh = meshes[i].bake_mesh_from_current_skeleton_pose()
			for n in sup_mesh.get_surface_count():
				var sf = sup_mesh.surface_get_arrays(n)
				vertices.append_array(sf[Mesh.ARRAY_VERTEX])
		var faces:PackedInt32Array = SE.SEU.get_all_faces(ref_mesh)
		var uvs:PackedVector3Array = SE.SEU.get_all_uvs(ref_mesh)
		f.store_32(len(vertices))
		f.store_32(len(faces)/3)
		for n:Vector3 in vertices:
			f.store_float(n.x * 100)
			f.store_float(n.y * 100)
			f.store_float(n.z * 100)
		for n in uvs:
			f.store_float(n.x)
			f.store_float(n.y)
		if normal_check:
			var normals:PackedVector3Array = SE.SEU.get_all_normals(ref_mesh)
			for n in normals:
				f.store_float(n.x)
				f.store_float(n.y)
				f.store_float(n.z)
			#print(len(normals))
		if color_check:
			var colors:PackedColorArray = SE.SEU.get_all_colors(ref_mesh)
			
			for n in colors:
				f.store_8(n.r8)
				f.store_8(n.g8)
				f.store_8(n.b8)
				f.store_8(n.a8)
		if weight_check:
			var indices:PackedInt32Array = SE.SEU.get_all_weight_indices(ref_mesh)
			var weights:PackedFloat32Array = SE.SEU.get_all_weights(ref_mesh)
			#if meshes[i].skin:
			#	for n in meshes[i].skin.get_bind_count():
			#		f2.store_string(CSK.get_bone_name(meshes[i].skin.get_bind_bone(n)) + "     " + str(n) + "   " + meshes[i].name + "\n")
			var sel_index:int = 0
			var type_:int = 0
			if CSK.get_bone_count() <= 4294967295:
				type_ = 2
			if CSK.get_bone_count() <= 65535:
				type_ = 1
			if CSK.get_bone_count() <= 255:
				type_ = 0
					
					
				
			for n in vertices:
				for a in 4 if skin4mode else 8:
					if !meshes[i].skin:
						if type_ == 0:
							f.store_8(indices[sel_index])
						elif type_ == 1:
							f.store_16(indices[sel_index])
						else:
							f.store_32(indices[sel_index])
					else:
						if type_ == 0:
							f.store_8(meshes[i].skin.get_bind_bone(indices[sel_index]))
						elif type_ == 1:
							f.store_16(meshes[i].skin.get_bind_bone(indices[sel_index]))
						else:
							f.store_32(meshes[i].skin.get_bind_bone(indices[sel_index]))
					#print(CSK.get_bone_name(indices[sel_index]))
					f.store_float(weights[sel_index])
					sel_index += 1
			#print(f.get_position())
		var mtype:int = 0
		if len(vertices) <= 4294967295:
			mtype = 2
		if len(vertices) <= 65535:
			mtype = 1
		if len(vertices) <= 255:
			mtype = 0
			
		var face_selector:int = 0
		#print(len(faces))
		for n in faces:
			if mtype == 0:
				f.store_8(n)
			if mtype == 1:
				f.store_16(n)
			if mtype == 2:
				f.store_32(n)
		#print(f.get_position())
		var sel_mats:Array = []
		for n in mats:
			var index: int = semat.find(n)
			#print(index)
			#print(n, "    ", mats[index])
			sel_mats.append(index)

		for n in range(0,sel_mats.size()):
			f.store_32(sel_mats[n])
	for i in semat:
		f.store_string(i.resource_name)
		f.store_8(0)
		if i.albedo_texture:
			f.store_8(1)
			f.store_string(i.albedo_texture.resource_name)
			f.store_8(0)
			
			if i.normal_texture:
				f.store_string(i.normal_texture.resource_name)
				f.store_8(0)
			else:
				f.store_8(0)


			if i.metallic_texture:
				f.store_string(i.metallic_texture.resource_name)
				f.store_8(0)
			else:
				f.store_8(0)
				
				
		else:
			f.store_8(0)
	for i in 1024:
		f.store_8(0)
	while f.get_position() % 4 != 0:
		f.store_8(0)
		
		#print("---------")
	#uv,normal,color,weight
