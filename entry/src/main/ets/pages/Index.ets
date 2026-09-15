import router from '@ohos.router';
import http from '@ohos.net.http';
import { SideMenu } from './SideMenu';
import { UniversalAction } from './UniversalAction';
import { FirstAidStep, ActionType, TestQuestion } from '../mock/types';
import { fetchRandomQuestions } from '../mock/testData';
import {
  cprData, chokingUnder1Data, chokingOver1Data,
  drowningData, burnData, fallData, ingestionData,
  feverUnder3Data, feverOver3Data
} from '../mock/FirstAidData';

import { TokenManager } from '../api/tokenManager';
import { SendCodeRequest, RegisterRequest, LoginRequest,LogoutRequest } from '../api/apiTypes';
import { ApiService } from '../api/apiService';

// 1. 发送验证码
async function sendCode() {
  try {
    await ApiService.httpRequest<void>(
      '/auth/send-code',
      http.RequestMethod.POST,
      { number: '13800138000', purpose: 'register' } as SendCodeRequest
    );
    // 成功后的处理，比如提示“验证码已发送”
  } catch (error) {
    // 错误处理
  }
}

// 2. 注册
async function register() {
  try {
    const token = await ApiService.httpRequest<string>('/auth/register', http.RequestMethod.POST, {
      number: '13800138000',
      code: '123456',
      password: 'MyPass123'
    } as RegisterRequest);

    // token 就是后端返回的 data 字段
    // 修正：根据报错提示，方法名可能是 setToken 而不是 saveToken
    await TokenManager.setToken(token);
  } catch (error) {
    // 错误处理
  }
}

// 3. 登录
async function login() {
  try {
    const token = await ApiService.httpRequest<string>('/auth/login', http.RequestMethod.POST, {
      number: '13800138000',
      password: 'MyPass123'
    } as LoginRequest);

    // 登录成功，token 已自动存入本地（通过响应拦截器）
    // 跳转到主页
  } catch (error) {
    // 错误处理
  }
}

// 4. 登出
async function logout() {
  try {
    // 登出接口，如果不需要传参可以直接传 undefined 或空对象
    await ApiService.httpRequest<void>('/auth/logout', http.RequestMethod.POST, {
      number: '13800138000'
    } as LogoutRequest);

    // 清除本地 token，跳转登录页
    await TokenManager.logout();
  } catch (error) {
    // 错误处理
  }
}

// 5. 发送聊天消息（注意：聊天接口是 SSE 流式返回，不能简单用 post 方法）



interface ScenarioItem {
  title: string;
  sub?: string;
  key: string;
  needAgeSelect: boolean;
  ageOptions?: AgeOptionItem[];
}

interface AgeOptionItem {
  label: string;
  key: string;
}


const SCENARIO_DATA: ScenarioItem[] = [
  {
    title: "气道异物梗阻",
    key: "choking",
    needAgeSelect: true,
    ageOptions: [
      { label: "未满 1 岁", key: "choking_under_1" }  as AgeOptionItem,
      { label: "满 1 岁至 6 岁", key: "choking_over_1" } as AgeOptionItem
    ]
  },
  {
    title: "发热伴惊厥抽搐",
    key: "fever",
    needAgeSelect: true,
    ageOptions: [
      { label: "未满 3 月龄", key: "fever_under_3" } as AgeOptionItem,
      { label: "3 月龄及以上", key: "fever_over_3" } as AgeOptionItem
    ]
  },
  // 以下场景不需要选择年龄，直接传对应的 key 即可
  { title: "跌倒与头部外伤", key: "fall", needAgeSelect: false },
  { title: "烫伤与烧伤", key: "burn", needAgeSelect: false },
  { title: "误服与异物摄入", key: "ingestion", needAgeSelect: false },
  { title: "溺水", key: "drowning", needAgeSelect: false },
];


@Entry
@Component
struct Index {
  @State inputValue: string = '';
  @State isMenuVisible: boolean = false;
  @State showOverlay: boolean = true;

  // 核心业务状态机
  @State currentStage: string = 'idle'
  @State selectedScenario: string = '';
  @State currentFirstAidStep: number = 0;
  @State currentQuestionIndex: number = 0;
  @State selectedOption: number = -1;
  private totalQuestions: number = 5;
  @State questions: TestQuestion[] = [];
  @State selectedIndex: number = -1;
  @State currentStepIndex: number = 0
  @State isStepCompleted: boolean = false;
  @State showDetailInfo: boolean = false;
  @State tempSelectedCategory: ScenarioItem | null = null; // 暂存选中的大类
  @State showAgeSelector: boolean = false; // 是否显示年龄选择器


  // ================= 数据获取方法 =================
  getCurrentTrainingData(): FirstAidStep[] {
    switch (this.selectedScenario) {
      case 'drowning':
        return drowningData;
      case 'burn':
        return burnData;
      case 'fall':
        return fallData;
      case 'ingestion':
        return ingestionData;
      case 'fever_under_3':
        return feverUnder3Data;
      case 'fever_over_3':
        return feverOver3Data;
      case 'choking_under_1':
        return chokingUnder1Data;
      case 'choking_over_1':
        return chokingOver1Data;
      case 'cpr':
        return cprData;
      default:
        return [];
    }
  }


  // ================= 流程控制函数 =================
  startTraining() {
    this.currentStage = 'select_scenario';
  }


  selectScenario(key: string) {
    this.selectedScenario = key;
    this._currentTrainingSteps = this.getCurrentTrainingData();
    this.questions = fetchRandomQuestions(key);
    this.currentQuestionIndex = 0;
    this.selectedOption = -1;
    this.currentStage = 'pre_test';
    this.currentStepIndex = 0;
    this.isStepCompleted = false;
    this.showDetailInfo = false;
    console.log('已选择场景: ' + key + ', 题目数量: ' + this.questions.length);
  }

  nextQuestion() {
    // 1. 如果当前不是最后一题，索引 +1
    if (this.currentQuestionIndex < this.totalQuestions - 1) {
      this.currentQuestionIndex++;
      this.selectedOption = -1; // 切换题目时，重置选项状态
    } else {
      // 2. 如果是最后一题，点击“完成”后的逻辑
      // 例如：提交成绩，或者切换 currentStage 退出测试弹窗
      console.log('测试完成');
      this.finishCurrentStage();
    }
  }

  finishCurrentStage() {
    if (this.currentStage === 'pre_test') {
      this.currentStage = 'training';
    } else if (this.currentStage === 'post_test') {
      this.currentStage = 'idle';
    }
  }

  finishTraining() {
    this.currentQuestionIndex = 0;
    this.selectedOption = -1;
    this.currentStage = 'post_test';
  }
  @State private _currentTrainingSteps: FirstAidStep[] = [];

  aboutToAppear() {
    this.questions = [];  // 初始化为空数组
    console.log('Index页面已加载，等待用户选择场景');
  }


  build() {
    Stack({ alignContent: Alignment.TopStart }) {

      // ==========================================
      // 第一部分：主界面
      // ==========================================
      Column() {
        Row() {
          Text('☰')
            .fontSize(26)
            .fontColor('#999')
            .margin({ left: 16, top: 10 })
            .onClick(() => {
              this.isMenuVisible = true;
            })
        }
        .width('100%')

        Blank()

        Column() {
          Row({ space: 10 }) {
            Button('急救培训')
              .fontSize(15)
              .backgroundColor('#EAEAEA')
              .fontColor('#333')
              .borderRadius(20)
              .onClick(() => {
                // 1. 重置培训进度
                this.currentStepIndex = 0;
                this.isStepCompleted = false;
                this.showDetailInfo = false;
                this.currentStage = 'select_scenario';
                this.selectedScenario = '';
              })

            Button('知识测试').fontSize(15).backgroundColor('#EAEAEA').fontColor('#333').borderRadius(20)
            Button('实战演练').fontSize(15).backgroundColor('#EAEAEA').fontColor('#333').borderRadius(20)
          }
          .width('100%')
          .margin({ bottom: 12 })
          .justifyContent(FlexAlign.SpaceEvenly)

          Row() {
            Image($r('app.media.xiangj'))
              .width(28).height(28).fillColor('#999')
            TextInput({ placeholder: '点击输入...', text: this.inputValue })
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .fontSize(16)
              .margin({ left: 8 })
            Image($r('app.media.mm'))
              .width(28)
              .height(28)
              .margin({ left: 8, right: 8 })
              .fillColor('#999999')
            Image($r('app.media.jiah'))
              .width(28).height(28).fillColor('#999')
          }
          .width('95%')
          .height(50)
          .backgroundColor('#F0F0F0')
          .borderRadius(20)
          .padding({ left: 12, right: 12 })
          .margin({ bottom: 20 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)

      // ==========================================
      // 第二部分：侧边栏菜单
      // ==========================================
      if (this.isMenuVisible) {
        Column() {}
        .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => { this.isMenuVisible = false; })
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
        .zIndex(99)
      }
      if (this.isMenuVisible) {
        SideMenu({ onClose: () => { this.isMenuVisible = false; } })
          .width('75%').height('100%').backgroundColor(Color.White)
          .translate({ x: this.isMenuVisible ? 0 : '-100%' })
          .animation({ duration: 300, curve: Curve.EaseOut })
          .zIndex(100)
      }

      // ==========================================
      // 第三部分：场景选择弹窗
      // ==========================================
      if (this.currentStage === 'select_scenario') {
        // 遮罩层，点击可关闭弹窗
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .position({ x: 0, y: 0 })
          .zIndex(200)
          .onClick(() => {
            this.showOverlay = false;
          })

        // 弹窗主体
        Column() {
          Text('请选择急救场景')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')
            .padding({ left: 24, top: 24, bottom: 16 })

          if (this.showAgeSelector && this.tempSelectedCategory) {
            // 显示年龄选择
            Column({ space: 20 }) {
              Text(`请选择年龄段：${this.tempSelectedCategory.title}`)
                .fontSize(18).fontWeight(FontWeight.Bold).margin({ bottom: 20 })

              // 循环渲染年龄按钮
              ForEach(this.tempSelectedCategory.ageOptions || [], (ageOpt: AgeOptionItem) => {
                Button(ageOpt.label)
                  .width('80%')
                  .height(50)
                  .fontSize(16)
                  .backgroundColor('#E6F7FF')
                  .fontColor('#007AFF')
                  .onClick(() => {
                    // 选中年龄后，开始培训
                    this.selectScenario(ageOpt.key);
                    this.showOverlay = false; // 关闭大弹窗
                    this.showAgeSelector = false; // 重置状态
                  })
              })

              Button('返回上一步')
                .type(ButtonType.Normal)
                .fontColor('#FFFFFF')
                .borderRadius(25)
                .onClick(() => {
                  this.showAgeSelector = false; // 返回场景选择
                })
            }
            .width('100%')
            .padding(20)
          } else {
            // 显示场景列表
            Scroll() {
              Column({ space: 12 }) {
                ForEach(SCENARIO_DATA, (item: ScenarioItem, index: number) => {
                  Row() {
                    Text(item.title)
                      .fontSize(16)
                      .fontColor('#333333')
                      .fontWeight(FontWeight.Medium)

                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .padding(16)
                  .backgroundColor(this.selectedIndex === index ? '#E6F7FF' : '#F5F5F5')
                  .borderRadius(12)
                  .onClick(() => {
                    this.selectedIndex = index;
                  })
                }, (item: ScenarioItem, index: number) => `${index}-${item.title}`)
              }
              .width('100%')
              .padding({ left: 16, right: 16, bottom: 16 })
            }
            .width('100%')
            .height(380)
            .scrollBar(BarState.On)
            .align(Alignment.Start)

            // 底部按钮
            Button('下一步')
              .fontSize(16)
              .width('90')
              .height(40)
              .backgroundColor(this.selectedIndex === -1 ? '#A0A0A0' : '#4CAF50')
              .fontColor('#FFFFFF')
              .borderRadius(25)
              .margin({
                top: 20,
                bottom: 10,
                left: 20,
                right: 20
              })
              .enabled(this.selectedIndex !== -1)
              .onClick(() => {
                if (this.selectedIndex === -1) {
                  console.log('请先选择一个急救场景');
                } else {
                  const selectedScenario = SCENARIO_DATA[this.selectedIndex];
                  // 判断是否需要选择年龄
                  if (selectedScenario.needAgeSelect) {
                    this.tempSelectedCategory = selectedScenario;
                    this.showAgeSelector = true; // 显示年龄选择器
                  } else {
                    // 不需要选年龄，直接开始
                    this.selectScenario(selectedScenario.key);
                    this.showOverlay = false;
                  }
                }
              })
          }
        }

        .width('90%')
        .height('80%')
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .position({ x: '5%', y: '10%' })
        .zIndex(201) // 确保弹窗内容在遮罩层之上
        .shadow({
          radius: 12,
          color: 'rgba(0,0,0,0.15)',
          offsetX: 0,
          offsetY: 8
        })
      }

      // ==========================================
      // 第四部分：通用测试弹窗
      // ==========================================
      if (this.currentStage === 'pre_test' || this.currentStage === 'post_test') {
        Column() {
        }
        .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.6)')
        .zIndex(200)

        Column() {
          Row() {
            Text(this.currentStage === 'pre_test' ? '培训摸底测试' : '培训结业测试')
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333')
            Blank()
            Text('跳过')
              .fontSize(16).fontColor('#666')
              .onClick(() => {
                this.finishCurrentStage();
              })
          }
          .width('100%')
          .padding({
            left: 24,
            right: 24,
            top: 24,
            bottom: 12
          })

          Scroll() {
            Column({ space: 15 }) {
              // 显示真实的题目内容
              Text(this.questions[this.currentQuestionIndex]?.content ?? '暂无题目')
                .fontSize(16).fontColor('#333').width('100%').textAlign(TextAlign.Start)

              // 循环显示真实的选项
              ForEach(this.questions[this.currentQuestionIndex]?.options || [], (option: string, index: number) => {
                Row() {
                  Text(option) // 直接显示选项内容
                    .fontSize(16)
                    .fontColor(this.selectedOption === index ? '#FFFFFF' : '#333333')
                }
                .width('100%')
                .height(50)
                .padding({ left: 20 })
                .alignItems(VerticalAlign.Center)
                .backgroundColor(this.selectedOption === index ? '#0D8AFF' : '#F5F5F5')
                .borderRadius(12)
                .onClick(() => {
                  this.selectedOption = index; // 记录选中的是第几个选项（索引）
                })
              }, (option: string, index: number) => index.toString())


            }
            .width('100%').padding({ left: 24, right: 24, bottom: 20 })
          }
          .layoutWeight(1).width('100%').scrollBar(BarState.Off)

          Button(this.currentQuestionIndex === this.totalQuestions - 1 ? '完成' : '下一题')
            .width('90%')
            .height(48)
            .backgroundColor('#0D8AFF')
            .borderRadius(24)
            .fontSize(18)
            .fontColor(Color.White)
            .margin({ bottom: 30 })
            .onClick(() => {
              this.nextQuestion();
            })
        }
        .width('90%')
        .height('60%')
        .backgroundColor(Color.White)
        .borderRadius(24)
        .position({ x: '5%', y: '20%' })
        .zIndex(201)
        .transition(
          TransitionEffect.translate({ y: 100 }).combine(TransitionEffect.opacity(1).animation({ duration: 300 })))
      }

      // ==========================================
      // 第五部分：急救培训内容页

      if (this.currentStage === 'training') {

        Column() {
          // 1. 有数据且没结束时，显示交互步骤
          if (this._currentTrainingSteps.length > 0 && this.currentStepIndex < this._currentTrainingSteps.length) {

            Column() {

              Row() {
                Text(`第${this.currentStepIndex + 1}步：${this._currentTrainingSteps[this.currentStepIndex].title}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333')
              }
              .width('90%')
              .justifyContent(FlexAlign.Start)
              .margin({ top: 20, bottom: 10 })

              Row() {
                Text(this._currentTrainingSteps[this.currentStepIndex].description)
                  .fontSize(18)
                  .fontColor('#555')
                  .padding(15)
                  .backgroundColor('#F0F8FF')
                  .width('95%')
                  .height(100)
                  .borderRadius(15)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding({ left: 20 })

            // 【区域2：3D/动画模拟展示区】
            Column() {
              Text(`🎬 正在演示：${this._currentTrainingSteps[this.currentStepIndex].title}`)
                .fontSize(18)
                .fontColor('#007AFF')
              Text('（此处替换为你的3D动画或视频组件）')
                .fontSize(14)
                .fontColor('#999')
                .margin({ top: 10 ,bottom:10})
            }
            .width('90%')
            .height(200)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor('#F9F9F9')
            .borderRadius(15)
            .margin({ top: 20, bottom: 20 })

            // 【区域3：确认机制与交互区】
            // 只有当用户没有点击“没看懂”时，才显示操作按钮
            if (!this.showDetailInfo) {
              Column({ space: 15 }) {
                // 模拟交互区域
                if (this._currentTrainingSteps[this.currentStepIndex]) {
                  UniversalAction({
                    currentStep: this._currentTrainingSteps[this.currentStepIndex],
                    onStepComplete: () => {
                      this.isStepCompleted = true;
                    }
                  })
                    .margin({ top: 10 })
                }

                // 确认按钮组
                if (this.isStepCompleted) {
                  Row({ space: 15 }) {
                    Button('没看懂 / 慢动作')
                      .type(ButtonType.Normal)
                      .backgroundColor(Color.White)
                      .fontColor('#FF9800')
                      .border({ width: 1, color: '#FF9800' })
                      .layoutWeight(1)
                      .onClick(() => {
                        this.showDetailInfo = true; // 触发子程序：显示详细解释
                      })

                    Button('已掌握，下一步')
                      .type(ButtonType.Capsule)
                      .backgroundColor('#007AFF')
                      .layoutWeight(1)
                      .onClick(() => {
                        // 判断是不是最后一步
                        if (this.currentStepIndex < this._currentTrainingSteps.length - 1) {
                          this.currentStepIndex += 1;
                          this.isStepCompleted = false; // 重置状态
                          this.showDetailInfo = false;  // 重置解释状态
                        } else {
                          // 全部完成，进入小结与结业测试
                          this.currentStage = 'post_test';
                        }
                      })
                  }
                  .width('90%')
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            }
            // 如果用户点了“没看懂”，显示详细解释（子程序）
            else {
              Column({ space: 15 }) {
                Row() {
                  Text(`💡 详细解释：${this._currentTrainingSteps[this.currentStepIndex].description}（请仔细观察动画细节，确保动作规范。）`)
                    .fontSize(15)
                    .fontColor('#D32F2F')
                    .padding(15)
                    .backgroundColor('#FFF0F0')
                    .borderRadius(15)
                }
                .width('90%')

                Button('我明白了，返回操作')
                  .width('80%')
                  .height(45)
                  .borderRadius(25)
                  .backgroundColor('#FF9800')
                  .onClick(() => {
                    this.showDetailInfo = false; // 关闭解释，回到正常流程
                  })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            }

          }
          // 2. 所有步骤都完成了，显示最终完成提示（流程闭环小结）
          else if (this._currentTrainingSteps.length > 0) {
            Text('🎉 恭喜！您已顺利完成所有培训步骤。')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
              .margin({ bottom: 20 })
            Text('建议前往实战演练模块进行巩固')
              .fontSize(14)
              .fontColor('#888')
              .margin({ bottom: 30 })

            Button('前往结业测试')
              .width('80%')
              .height(50)
              .borderRadius(25)
              .backgroundColor('#4CAF50')
              .onClick(() => {
                this.questions = fetchRandomQuestions(this.selectedScenario);
                this.currentQuestionIndex = 0;
                this.selectedOption = -1;
                this.currentStage = 'post_test';
              })
          }
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .margin({top:20,bottom:20})
        .backgroundColor(Color.White)
      }
    }
  }
}
