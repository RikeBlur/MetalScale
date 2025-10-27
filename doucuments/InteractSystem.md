# Interact System
广义的交互类，指所有 玩家 和 其他实体（NPC、场景）的相互影响。 <br>
所有 interct 相关的组件 component 都要一个 area2d 作为碰撞箱（利用 _on_area_entered 信号）。 <br>

## 1. 基本组件 INTERACT/INTERACTED

### InteractedComponent
Layer = 8 <br>
作为 Area2D 节点的**第一个**子节点！（Area2D interacted_range 作为可以触发 interactable 的范围）<br>
inter_com : 暂存触发者（InteractComponent， 也应该是 Area2D 的**第一个**子节点），在其 rage 进入触发范围后，
将触发者的 interact 信号和 _on_interact 连接。<br>
主要信号： <br>
interacted：成功触发 <br>
be_interactable：进入可触发状态 <br>
be_not_interactable：进入不可触发状态 <br>

### InteractComponent
Layer = 7 <br>
作为 Area2D 节点的**第一个**子节点！（Area2D interact_range 作为可以触发的范围）<br>
只有一个信号 interact ， Input 输入 “interact” 后 发送该信号。是否能被接收完全由 InteractedComponent 决定 <br>
 
### 注意
INTERACT 是个富信号系统，只负责信号交互，视作封装系统的话，最终信号主要有 InteractedComponent 输出 <br>

## 2. 基本组件 HURT/DAMAGE

### DamageComponent
Layer = 6 <br>
target_group ： 只对特定目标施加伤害，所以需要传入一个字符串表达目标的 group（如enemy、player） <br>
base_damage_num/damage_factor/min_damage/max_damage ： 计算伤害，base_damage_num*damage_factor，限制在
 min 和 max 之间（如果低于 min ，不发生伤害事件） <br>
damage_cooldown ： 伤害冷却，每个 HurtedComponent 被触发 _on_hurt 后，将其 Area2D 节点id保存到 
area_cooldowns (字典)中，当 cooldown 计数完毕移除该 Area2D <br>
_on_area_entered时，如果没有不处于伤害冷却，直接调用对应的 HurtedComponet 的 _on_hurt 方法 <br>

### HurtedComponent
Layer = 5 <br>
必须是一个 Area2D 节点的父节点！（HitBox） <br>
hit_flash_player ： （AnimationPlayer类） AnimatedSprite2D 的子节点，控制 AnimatedSprite2D 的 material
中的参数（hit_flash_intensity），通过播放实现受击闪烁效果。 <br>
hurted_audio/hurted_effect/die_audio/die_effect <br>
health_bar ： 悬浮血条，暂时不需要 <br>
_on_hurt : 传入一个 float 类的 amount，表示扣血量 <br>
health_max 从 entity 读取；health需要同步给 entity <br>

### 注意
HURT/DAMAGE 是个贫信号系统，所有交互不由信号负责，直接跨节点调用方法，所以可扩展度有限。 <br>
