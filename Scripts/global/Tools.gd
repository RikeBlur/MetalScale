extends Node

# --------------------------------------------节点查找工具-------------------------------------------
# 从指定节点 查找父级CharacterBody2D
# 因为所有的判定基本都依赖Area2D节点，如伤害判定，拾取判定
#这个函数可以直接从Area向上检索父节点对象
func _find_character_body_parent(node: Node2D) -> CharacterBody2D:
	if node is CharacterBody2D:
		return node
	var parent = node.get_parent()
	if parent is CharacterBody2D:
		return parent
	# 递归向上查找，直到找到RigidBody2D或达到场景根
	if parent and parent != get_tree().root:
		return _find_character_body_parent(parent)
	return null
	
# -----------------------------------------------------------------------------------------------------
