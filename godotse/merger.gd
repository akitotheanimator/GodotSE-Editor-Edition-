@tool

extends TextureRect

var tool_plugin:Node


var skel_merge_from:Array
var skel_merge_to:Skeleton3D
@onready var sel1:Label = $SEL1
@onready var sel2:Label = $SEL2
@onready var opt:OptionButton = $PROC4/INDE_SEL

func add_temp_nodes() -> void:
	skel_merge_from = tool_plugin.get_selected_nodes()
	sel1.text = ""
	for i:Skeleton3D in skel_merge_from:
		sel1.text += i.name + ", "
	sel1.text = sel1.text.substr(0, sel1.text.length() - 2)
func add_targ_node() -> void:
	skel_merge_to = tool_plugin.get_selected_nodes()[0]
	
	var last_sel:String = opt.get_item_text(opt.get_item_index(opt.get_selected_id()))
	
	opt.clear()
	opt.add_separator("Select a bone to root merge!")
	
	
	for i:int in range(0,skel_merge_to.get_bone_count()):
		opt.add_item(skel_merge_to.get_bone_name(i))
	for i:int in range(0,opt.item_count):
		if opt.get_item_text(i) == last_sel:
			opt.selected = i
			break
	sel2.text = skel_merge_to.name



func find_array_name(Arrays:Array, old_name:String) -> String:
	for n:Array in Arrays:
		if n[0] == old_name:
			return n[1]
	return ""
func find_new_name(skeleton:Skeleton3D,bname:String) -> String:
	var fo:String = bname
	var fo_fin:String = fo
	
	var alli:int = 0
	while skeleton.find_bone(fo_fin) != -1:
		alli += 1
		fo_fin = fo + "_"+ str(alli)
	
	return fo_fin

func MERGE_BY_ROOT() -> void:
	var OLD_TRANSF:Transform3D = skel_merge_to.global_transform
	skel_merge_to.global_transform = Transform3D.IDENTITY
	skel_merge_to.reset_bone_poses()
	if opt.get_item_text(opt.get_item_index(opt.get_selected_id())) == "Select a bone to root merge!":
		push_error("ERROR: No bone to merge root selected.")
		return
	for i:Skeleton3D in skel_merge_from:
		if i == skel_merge_to:
			push_error("ERROR: Tried to merge the same skeleton.")
			return
	var ref_bone:int = skel_merge_to.find_bone(opt.get_item_text(opt.get_item_index(opt.get_selected_id())))
	for i:Skeleton3D in skel_merge_from:
		i.reset_bone_poses()
		var bones:PackedInt32Array = []
		traverse_skeleton(bones,i,0,true)
		
		var POSE:Transform3D = skel_merge_to.get_bone_global_pose(ref_bone)
		var REST:Transform3D = skel_merge_to.get_bone_rest(ref_bone)
		var PARENT_BNE:int = skel_merge_to.get_bone_parent(ref_bone)
		
		skel_merge_to.set_bone_parent(ref_bone,-1)
		skel_merge_to.set_bone_global_pose(ref_bone,i.get_bone_global_pose(0))
		skel_merge_to.set_bone_rest(ref_bone,i.get_bone_rest(0))
		
		#skel_merge_to.set_bone_parent(ref_bone,-1)
		var new_binds:Array = []
		
		for n:int in bones:
			var bname:String = i.get_bone_name(n)
			var nname:String = find_new_name(skel_merge_to, i.get_bone_name(n))
			
			new_binds.append([bname, nname])
			
		for n:int in range(0,len(bones)):
			var bname:String = find_new_name(skel_merge_to, i.get_bone_name(bones[n]))
			var pname:String = ""
			
			if i.get_bone_parent(n) != -1:
				pname = find_array_name(new_binds, i.get_bone_name(i.get_bone_parent(bones[n])))
			else:
				pname = find_array_name(new_binds, "")
			
			
			var nbone:int    = skel_merge_to.add_bone(bname)

			
			#print(newb[n][0],"     ",skel_merge_to.find_bone(newb[n][1]),"     ",skel_merge_to.find_bone(newb[n][2]))
			var parent:int = skel_merge_to.find_bone(pname)
			#print(bname, "    ",pname)
			if i.get_bone_parent(i.find_bone(i.get_bone_name(bones[n]))) != -1:
				skel_merge_to.set_bone_parent(nbone,parent)
			else:
				skel_merge_to.set_bone_parent(nbone,ref_bone)

			skel_merge_to.set_bone_rest(nbone,i.get_bone_rest(bones[n]))
			skel_merge_to.set_bone_global_pose(nbone,i.get_bone_global_pose(bones[n]))
			
			
			
			
			
			
		skel_merge_to.set_bone_parent(ref_bone,PARENT_BNE)
		skel_merge_to.set_bone_global_pose(ref_bone,POSE)
		skel_merge_to.set_bone_rest(ref_bone,REST)
		
		
		
		var meshes:Array = i.get_children()
		for m:MeshInstance3D in meshes:
			m.reparent(skel_merge_to)
			m.name = "SEMesh0"

			
		for m:MeshInstance3D in meshes:
			if m.skin:
				var sk:Skin = m.skin
				var sk_ret:Skin = Skin.new()
				
				sk_ret.set_bind_count(sk.get_bind_count())
				for ne:int in range(0,sk.get_bind_count()):
					var chosen:int = 0
					for nn:int in range(0,len(new_binds)):
						if i.get_bone_name(sk.get_bind_bone(ne)) == new_binds[nn][0]:
							chosen = nn
							break
					
					var found:int = skel_merge_to.find_bone(new_binds[chosen][1])
					sk_ret.set_bind_bone(ne,found)
					sk_ret.set_bind_pose(ne,sk.get_bind_pose(ne))
					
					
				m.skin = sk_ret
			m.skeleton = m.get_path_to(skel_merge_to)
		i.free()
	apply_pose_as_rest_pose(skel_merge_to)
	skel_merge_to.global_transform = OLD_TRANSF
func MERGE_BY_NAME() -> void:
	var OLD_TRANSF:Transform3D = skel_merge_to.global_transform
	skel_merge_to.global_transform = Transform3D.IDENTITY
	skel_merge_to.reset_bone_poses()
	for i:Skeleton3D in skel_merge_from:
		if i == skel_merge_to:
			push_error("ERROR: Tried to merge the same skeleton.")
			return
		
	for i:Skeleton3D in skel_merge_from:
		i.reset_bone_poses()
		var ref_bone:int = skel_merge_to.find_bone(i.get_bone_name(0))
		if ref_bone != -1:
			var bones:PackedInt32Array = []
			traverse_skeleton(bones,i,0,false)
			var POSE:Transform3D = skel_merge_to.get_bone_global_pose(ref_bone)
			var REST:Transform3D = skel_merge_to.get_bone_rest(ref_bone)
			var PARENT_BNE:int = skel_merge_to.get_bone_parent(ref_bone)
			
			skel_merge_to.set_bone_parent(ref_bone,-1)
			skel_merge_to.set_bone_rest(ref_bone,i.get_bone_rest(0))
			skel_merge_to.set_bone_global_pose(ref_bone,i.get_bone_global_pose(0))
			
			#skel_merge_to.set_bone_parent(ref_bone,-1)
			
			for n:int in bones:
				var nbone:int = skel_merge_to.add_bone(i.get_bone_name(n))
				skel_merge_to.set_bone_parent(nbone,skel_merge_to.find_bone(i.get_bone_name(i.get_bone_parent(n))))
				#skel_merge_to.set_bone_rest(nbone,i.get_bone_rest(n))
				
				skel_merge_to.set_bone_global_pose(nbone,i.get_bone_global_pose(n))
				#skel_merge_to.set_bone_pose(nbone,Transform3D.IDENTITY)
				
				
				
			skel_merge_to.set_bone_parent(ref_bone,PARENT_BNE)
			skel_merge_to.set_bone_rest(ref_bone,REST)
			skel_merge_to.set_bone_global_pose(ref_bone,POSE)
			
			
			var meshes:Array = i.get_children()
			for m:MeshInstance3D in meshes:
				m.reparent(skel_merge_to)
				m.name = "SEMesh0"
			
			for m:MeshInstance3D in meshes:
				if m.skin:
					var sk:Skin = m.skin
					var sk_ret:Skin = Skin.new()
					
					sk_ret.set_bind_count(sk.get_bind_count())
					
					for ne:int in range(0,sk.get_bind_count()):
						var ogName:String = i.get_bone_name(sk.get_bind_bone(ne))
						var bname:String = i.get_bone_name(sk.get_bind_bone(ne))
						var found:int = skel_merge_to.find_bone(bname)

						sk_ret.set_bind_bone(ne,found)
						sk_ret.set_bind_pose(ne,sk.get_bind_pose(ne))
					m.skin = sk_ret
				m.skeleton = m.get_path_to(skel_merge_to)
			i.free()
	apply_pose_as_rest_pose(skel_merge_to)
	skel_merge_to.global_transform = OLD_TRANSF
func traverse_skeleton(bone_array:PackedInt32Array,skeleton:Skeleton3D,index:int,include_first:bool) -> void:
	if include_first:
		bone_array.append(index)
	for i:int in skeleton.get_bone_children(index):
		traverse_skeleton(bone_array,skeleton,i,true)
func apply_pose_as_rest_pose(skeleton:Skeleton3D) -> void:
	if skeleton == null:
		push_error("Skeleton is not assigned.")
		return
	
	var bone_count:int = skeleton.get_bone_count()
	
	for i:int in range(0,bone_count):
		skeleton.set_bone_rest(i, skeleton.get_bone_pose(i))
