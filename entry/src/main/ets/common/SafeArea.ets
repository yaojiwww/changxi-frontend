// 全局安全区尺寸（沉浸式布局下，状态栏/小白条各占多高，单位 vp）
// EntryAbility 启动时从窗口避让区读取一次，写入这里的静态字段；
// 各页面读取后做 padding，即可适配任何机型（不写死数字）
export class SafeArea {
  static topVp: number = 0;     // 状态栏高度
  static bottomVp: number = 0;  // 底部小白条高度
}
