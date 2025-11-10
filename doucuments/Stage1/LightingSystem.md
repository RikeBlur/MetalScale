# Lighting System

## 逻辑光源：LightSource 
对应group ： light_source
### 基本原理
通过对照射范围和遮挡的 栅格化采样 和 射线检测，确保每个点的光照强度可以计算。<br>
一般会有一个渲染光照的 PointLight2D 节点，存储为变量 point_light_2d。<br>
### 核心参数
radius : 光源半径 <br>
logic_energy : 光源处的 Intensity （最大） <br>
**sampling_rate** ： 栅格化采样数 <br>
**threshold** : 对于射线 SampleRay 和遮挡点的相交判定阈值 <br>
### 重要方法
initialize_sample_rays： 为每个角度分配对应编号的 SampleRay。 <br>
update_ray_collisions ： 对每个 SampleRay 计算是否与遮挡点有交点， 如果有，需计算这个 
SampleRay 的实际有效长度ray_length （交点到光源距离）。这个方法在遮挡点有变化时调用。<br>
calculate_intensity ： 按照输入位置与光源的角度和距离，计算 Intensity。如果所在角度的 SampleRay 
已经被遮挡且 有效长度ray_length 小于距离，则返回0，否则按 1 - length / radius 计算 Intensity （0到1）<br>
### 分类
radial_light_source : 圆形（辐射）光源。光强均匀的分布在每个角度。
parallel_light_source : 锥形光源。光强分布在一个特定的角度范围。
（angle_offset+angle_range 到 angle_offset-angle_range）<br>

## 逻辑探测器：LightDetector
对应group ： light_detector
### 基本原理
将探测器周围的光源设为 近光源 ，计算探测器相对于每个近光源位置（角度、距离）的 Intensity 并求和。<br>
注意，为了确保检测的鲁棒性和层次性，输出的 Intensity 分为 intensity_now 和 intensity_future，
分别由十字扩展的 5个点 求平均 和 八向扩展的 8个点 求平均。<br>
### 核心参数
radius ： 探测器的 近光源 检测距离 <br>
update_rate ： 测量值Intensity 更新频率 <br>
extension_length ： 测量 intensity_now 时，十字扩展的扩展长度 <br>
future_length ： 测量 intensity_future 时，八向扩展的扩展长度 <br>
### 重要方法
get_now_detection_points ： 获取十字扩展的 5个点，用于计算 intensity_now <br>
get_future_detection_points ： 获取八向扩展的 8个点，用于计算 intensity_future <br>
calculate_intensities(is_now : bool) : 计算所有近光源的 intensity_now (is_now == true) 和 
intensity_future (is_now == false) 并求和, 返回值为float类型  <br>

## 逻辑统筹：LightingManager
### 主要功能
统计并存储场景树中的所有 LightSource、LightDetector、OcclusionPoint（遮挡点）；<br>
遮挡点计算（对应group：occlusion），目前只能对 LightOccluder2D 的多边形边缘按找一定长度采样；<br>
将 LightSource 周围的遮挡点分配给 LightSource；将 LightDetector 周围的 LightSource 分配给 LightDetector 。<br>
### 核心参数
**grid_size** ： 遮挡点采样时的长度间隔 <br>
**update_rate** ： 更新Updata 和 分配Assign 的频率 <br>
detecte_offset : 遮挡点分配给光源时，距离阈值为 光源的 radius + detecte_offset <br>
（光源分配给探测器时，距离阈值就是探测器的radius） <br>

## 性能优化
### 影响性能的参数
**sampling_rate** ： radial_light_source 36； parallel_light_source 9 （越小越快）<br>
**grid_size** : 10 （越大越快）<br>
**update_rate** ： 0.2 （越小越快）<br>
**threshold** ： 10 如果 grid_size 、 sampling_rate过小，为了避免性能太差，可以调高阈值。<br>
### 优化方向
每个 SampleRay 检查与所有 遮挡点 计算交点（双循环），非常慢慢慢，需要优化 <br>
