import os
import uuid

def generate_slide_scene(question_text, answer_a_text, answer_b_text, answer_c_text, answer_d_text, output_folder, file_name):
    """
    生成类似slide_1_example_0.tscn的四项选择场景文件
    
    Args:
        question_text (str): 问题文本
        answer_a_text (str): A1选项文本
        answer_b_text (str): A2选项文本
        answer_c_text (str): A3选项文本
        answer_d_text (str): A4选项文本
        output_folder (str): 输出文件夹路径
        file_name (str): 输出文件名（不含扩展名）
    """
    
    # 生成随机UID（模拟Godot的UID系统）
    scene_uid = f"uid://{''.join([hex(ord(c))[2:] for c in str(uuid.uuid4())[:16]])}"
    
    # 场景模板
    scene_template = f"""[gd_scene load_steps=18 format=3 uid="{scene_uid}"]

[ext_resource type="Script" path="res://Scripts/slide_component/slide_component_1.gd" id="1_hmq75"]
[ext_resource type="Texture2D" uid="uid://dqodm34c1861l" path="res://Assests/sprite/矩形 1.png" id="3_ncq20"]
[ext_resource type="Script" path="res://Scripts/static_back.gd" id="5_l5r08"]
[ext_resource type="Material" uid="uid://bu51bywbbo0u2" path="res://Effect/Shader/dissolve/dissolve.tres" id="6_2nxfy"]
[ext_resource type="Theme" uid="uid://d2uhxdy50yhsv" path="res://Style/theme_01.tres" id="7_6tkih"]
[ext_resource type="Material" uid="uid://dolw1jajraj15" path="res://Effect/Shader/glowing_text/glowing_text.tres" id="8_53dal"]
[ext_resource type="AudioStream" uid="uid://cc2ppqru4b47t" path="res://Assests/SFX/interact/Fruit collect 1.wav" id="8_yojxx"]
[ext_resource type="Script" path="res://Scripts/interact/interactabel_label_component.gd" id="9_uiog4"]
[ext_resource type="Shader" path="res://Effect/Shader/glowing_text/glowing_text.gdshader" id="10_m2j8i"]
[ext_resource type="Script" path="res://Scripts/interact/botton_component.gd" id="11_uiaqk"]

[sub_resource type="ShaderMaterial" id="ShaderMaterial_nbx1y"]
shader = ExtResource("10_m2j8i")
shader_parameter/outline_width = 0.0
shader_parameter/all_color = Color(0.56, 0.063, 0.063, 1)

[sub_resource type="ShaderMaterial" id="ShaderMaterial_1roj0"]
shader = ExtResource("10_m2j8i")
shader_parameter/outline_width = 0.0
shader_parameter/all_color = Color(0.56, 0.063, 0.063, 1)

[sub_resource type="ShaderMaterial" id="ShaderMaterial_ed58s"]
shader = ExtResource("10_m2j8i")
shader_parameter/outline_width = 0.0
shader_parameter/all_color = Color(0.56, 0.063, 0.063, 1)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_bhf7i"]
size = Vector2(65.25, 36)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_b8q5c"]
size = Vector2(126, 36)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_34kdx"]
size = Vector2(65.25, 36)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_44oyq"]
size = Vector2(65.25, 36)

[node name="{file_name}" type="Node2D" node_paths=PackedStringArray("area_array") groups=["slide"]]
position = Vector2(0, 20)
script = ExtResource("1_hmq75")
area_array = [NodePath("A1"), NodePath("A2"), NodePath("A3"), NodePath("A4")]

[node name="D2" type="Sprite2D" parent="."]
position = Vector2(585, 303)
scale = Vector2(0.75, 0.680045)
texture = ExtResource("3_ncq20")
script = ExtResource("5_l5r08")

[node name="Control" type="Control" parent="."]
layout_mode = 3
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -1.0
offset_right = 1148.0
offset_bottom = 649.0
grow_horizontal = 2
grow_vertical = 2
size_flags_horizontal = 4
size_flags_vertical = 4
mouse_filter = 2

[node name="Q" type="Label" parent="Control"]
material = ExtResource("6_2nxfy")
layout_mode = 1
anchors_preset = -1
anchor_left = -7.262
anchor_top = -0.212
anchor_right = 8.262
anchor_bottom = 1.0
offset_left = -0.019989
offset_top = -0.0199995
offset_right = 0.019989
offset_bottom = 8.5
grow_horizontal = 2
grow_vertical = 2
theme = ExtResource("7_6tkih")
text = "{question_text}"
horizontal_alignment = 1
vertical_alignment = 1

[node name="A1" type="Label" parent="Control" node_paths=PackedStringArray("connected_area")]
material = SubResource("ShaderMaterial_nbx1y")
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -272.5
offset_top = 7.5
offset_right = -208.5
offset_bottom = 64.5
grow_horizontal = 2
grow_vertical = 2
theme = ExtResource("7_6tkih")
text = "{answer_a_text}"
horizontal_alignment = 1
vertical_alignment = 1
script = ExtResource("9_uiog4")
connected_area = NodePath("../../A1")

[node name="hoven" type="AudioStreamPlayer2D" parent="Control/A1"]
position = Vector2(470, -1)

[node name="click" type="AudioStreamPlayer2D" parent="Control/A1"]
stream = ExtResource("8_yojxx")

[node name="A2" type="Label" parent="Control" node_paths=PackedStringArray("connected_area")]
material = SubResource("ShaderMaterial_1roj0")
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -135.0
offset_top = 7.5
offset_right = -14.0
offset_bottom = 64.5
grow_horizontal = 2
grow_vertical = 2
theme = ExtResource("7_6tkih")
text = "{answer_b_text}"
horizontal_alignment = 1
vertical_alignment = 1
script = ExtResource("9_uiog4")
connected_area = NodePath("../../A2")

[node name="hoven" type="AudioStreamPlayer2D" parent="Control/A2"]
position = Vector2(470, -1)

[node name="click" type="AudioStreamPlayer2D" parent="Control/A2"]
stream = ExtResource("8_yojxx")

[node name="A3" type="Label" parent="Control" node_paths=PackedStringArray("connected_area")]
material = SubResource("ShaderMaterial_ed58s")
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = 45.5
offset_top = 7.5
offset_right = 105.5
offset_bottom = 64.5
grow_horizontal = 2
grow_vertical = 2
theme = ExtResource("7_6tkih")
text = "{answer_c_text}"
horizontal_alignment = 1
vertical_alignment = 1
script = ExtResource("9_uiog4")
connected_area = NodePath("../../A3")

[node name="hoven" type="AudioStreamPlayer2D" parent="Control/A3"]
position = Vector2(470, -1)

[node name="click" type="AudioStreamPlayer2D" parent="Control/A3"]
stream = ExtResource("8_yojxx")

[node name="A4" type="Label" parent="Control" node_paths=PackedStringArray("connected_area")]
material = ExtResource("8_53dal")
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = 201.5
offset_top = 6.5
offset_right = 257.5
offset_bottom = 63.5
grow_horizontal = 2
grow_vertical = 2
theme = ExtResource("7_6tkih")
text = "{answer_d_text}"
horizontal_alignment = 1
vertical_alignment = 1
script = ExtResource("9_uiog4")
connected_area = NodePath("../../A4")

[node name="hoven" type="AudioStreamPlayer2D" parent="Control/A4"]
position = Vector2(470, -1)

[node name="click" type="AudioStreamPlayer2D" parent="Control/A4"]
stream = ExtResource("8_yojxx")

[node name="A1" type="Area2D" parent="." node_paths=PackedStringArray("text")]
position = Vector2(0, 15)
script = ExtResource("11_uiaqk")
text = NodePath("../Control/A1")

[node name="CollisionShape2D" type="CollisionShape2D" parent="A1"]
position = Vector2(332.75, 345)
shape = SubResource("RectangleShape2D_bhf7i")

[node name="A2" type="Area2D" parent="." node_paths=PackedStringArray("text")]
position = Vector2(498, 360)
script = ExtResource("11_uiaqk")
text = NodePath("../Control/A2")

[node name="CollisionShape2D" type="CollisionShape2D" parent="A2"]
position = Vector2(2, 0)
shape = SubResource("RectangleShape2D_b8q5c")

[node name="A3" type="Area2D" parent="." node_paths=PackedStringArray("text")]
position = Vector2(648, 360)
script = ExtResource("11_uiaqk")
text = NodePath("../Control/A3")

[node name="CollisionShape2D" type="CollisionShape2D" parent="A3"]
position = Vector2(1, 0)
shape = SubResource("RectangleShape2D_34kdx")

[node name="A4" type="Area2D" parent="." node_paths=PackedStringArray("text")]
position = Vector2(802, 360)
script = ExtResource("11_uiaqk")
text = NodePath("../Control/A4")

[node name="CollisionShape2D" type="CollisionShape2D" parent="A4"]
position = Vector2(1, 0)
shape = SubResource("RectangleShape2D_44oyq")
"""

    # 确保输出文件夹存在
    os.makedirs(output_folder, exist_ok=True)
    
    # 生成完整的文件路径
    file_path = os.path.join(output_folder, f"{file_name}.tscn")
    
    # 写入文件
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(scene_template)
    
    print(f"✅ 四项选择场景文件已生成: {file_path}")
    return file_path

def batch_generate_slides_from_csv(csv_file_path, output_folder):
    """
    从CSV文件批量生成四项选择slide场景
    CSV格式: 文件名,问题,选项A,选项B,选项C,选项D
    """
    import csv
    
    if not os.path.exists(csv_file_path):
        print(f"❌ CSV文件不存在: {csv_file_path}")
        return
    
    generated_files = []
    
    with open(csv_file_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader, None)  # 跳过表头
        
        for row_num, row in enumerate(reader, start=2):
            if len(row) >= 6:
                file_name, question, answer_a, answer_b, answer_c, answer_d = row[:6]
                try:
                    file_path = generate_slide_scene(question, answer_a, answer_b, answer_c, answer_d, output_folder, file_name)
                    generated_files.append(file_path)
                except Exception as e:
                    print(f"❌ 第{row_num}行生成失败: {e}")
            else:
                print(f"⚠️ 第{row_num}行数据不完整，跳过 (需要6列: 文件名,问题,选项A,选项B,选项C,选项D)")
    
    print(f"\n🎉 批量生成完成! 共生成 {len(generated_files)} 个文件")
    return generated_files

def interactive_generator():
    """
    交互式生成器
    """
    print("🎮 Godot 四项选择 Slide 场景生成器")
    print("=" * 45)
    
    while True:
        print("\n请选择操作:")
        print("1. 单个生成")
        print("2. 批量生成 (从CSV文件)")
        print("3. 创建CSV模板")
        print("4. 退出")
        
        choice = input("\n请输入选择 (1-4): ").strip()
        
        if choice == "1":
            # 单个生成
            print("\n--- 单个四项选择场景生成 ---")
            question = input("请输入问题文本: ").strip()
            answer_a = input("请输入选项A文本: ").strip()
            answer_b = input("请输入选项B文本: ").strip()
            answer_c = input("请输入选项C文本: ").strip()
            answer_d = input("请输入选项D文本: ").strip()
            output_folder = input("请输入输出文件夹路径 (默认: ./generated_slides): ").strip() or "./generated_slides"
            file_name = input("请输入文件名 (不含扩展名): ").strip()
            
            if all([question, answer_a, answer_b, answer_c, answer_d, file_name]):
                generate_slide_scene(question, answer_a, answer_b, answer_c, answer_d, output_folder, file_name)
            else:
                print("❌ 输入信息不完整!")
        
        elif choice == "2":
            # 批量生成
            print("\n--- 批量四项选择场景生成 ---")
            csv_file = input("请输入CSV文件路径: ").strip()
            output_folder = input("请输入输出文件夹路径 (默认: ./generated_slides): ").strip() or "./generated_slides"
            
            if csv_file:
                batch_generate_slides_from_csv(csv_file, output_folder)
            else:
                print("❌ 请输入CSV文件路径!")
        
        elif choice == "3":
            # 创建CSV模板
            template_path = input("请输入模板文件路径 (默认: ./slide_4choice_template.csv): ").strip() or "./slide_4choice_template.csv"
            create_csv_template(template_path)
        
        elif choice == "4":
            print("👋 再见!")
            break
        
        else:
            print("❌ 无效选择!")

def create_csv_template(file_path):
    """
    创建四项选择CSV模板文件
    """
    template_content = """文件名,问题,选项A,选项B,选项C,选项D
slide_1,你认为你的床下面有什么?,尘埃,一具尸体,旧书,我
slide_2,你更喜欢哪种颜色?,红色,蓝色,绿色,黄色
slide_3,你最喜欢的季节是?,春天,夏天,秋天,冬天
slide_4,你更倾向于哪种学习方式?,阅读,听讲,实践,讨论"""

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(template_content)
    
    print(f"✅ 四项选择CSV模板已创建: {file_path}")

# 快速使用示例函数
def quick_example():
    """
    快速示例 - 生成一个测试场景
    """
    generate_slide_scene(
        question_text="Q11: 下面哪个词最适合形容你？",
        answer_a_text="坚定的",
        answer_b_text="骗子",
        answer_c_text="活泼的",
        answer_d_text="亲善的",
        output_folder="d:/godot/metal_scale/System/A/day_0",
        file_name="slide_1_10"
    )

if __name__ == "__main__":
    # 运行交互式生成器
    # interactive_generator()
    
    # 或者取消注释下面这行来运行快速示例
    quick_example()
