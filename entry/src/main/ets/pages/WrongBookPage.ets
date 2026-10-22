// 错题本：顶部 Tab（全部/近一周/今日/顽固错题）筛选，按知识点分类展示错题
// 分类头行点击进入重练答题页；每道题展示三次答对进度条（x/3）
// 三次答对消除逻辑由后端判断，前端仅做 UI 进度展示
import { WrongApi } from '../api/WrongApi';
import { WrongBookStore, WrongListResult, WrongCategory, WrongItem } from '../common/WrongBookStore';
import { TokenStore } from '../common/TokenStore';

const TIME_TABS: string[] = ['全部', '近一周', '今日', '顽固错题'];
const TIME_VALUES: string[] = ['all', 'week', 'today', 'stubborn'];

@Entry
@ComponentV2
struct WrongBookPage {
  @Local activeTab: number = 0;
  @Local result: WrongListResult = { categories: [], total: 0 };
  @Local loading: boolean = true;

  private token: string = '';

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      await WrongBookStore.init(context);
      await TokenStore.init(context);
    }
    this.token = await TokenStore.read();
    await this.refresh();
  }

  // 返回列表页时刷新（重练完成 back 回来后读取最新消除进度）
  onPageShow(): void {
    this.refresh();
  }

  private async refresh(): Promise<void> {
    this.loading = true;
    try {
      const res = await WrongApi.list('', TIME_VALUES[this.activeTab], this.token);
      if (res.code === 0 && res.data !== null) {
        this.result = res.data;
      }
    } catch (e) {
      // 静默失败，展示上次数据
    } finally {
      this.loading = false;
    }
  }

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  private switchTab(index: number): void {
    if (this.activeTab === index) {
      return;
    }
    this.activeTab = index;
    this.refresh();
  }

  // 进入该分类的错题重练答题页
  private gotoRetrain(category: string): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RetrainPage',
      params: {
        source: 'wrong',
        category: category,
        timeRange: TIME_VALUES[this.activeTab]
      }
    });
  }

  // 进度条颜色：0 橙、1 深橙、2 蓝（即将消除）
  private progressColor(count: number): string {
    if (count <= 0) {
      return '#FBDE71';
    }
    if (count === 1) {
      return '#FBDE71';
    }
    return '#E4842A';
  }

  @Builder
  TabBar() {
    Row() {
      ForEach(TIME_TABS, (t: string, i: number) => {
        Column({ space: 6 }) {
          Text(t)
            .fontSize(15.0)
            .fontWeight(this.activeTab === i ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.activeTab === i ? '#E4842A' : '#9A8A6E')
          Row()
            .width(22)
            .height(3)
            .borderRadius(1.5)
            .backgroundColor(this.activeTab === i ? '#FBDE71' : Color.Transparent)
        }
        .layoutWeight(1)
        .onClick(() => {
          this.switchTab(i);
        })
      }, (t: string, i: number) => `${i}_${t}`)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .padding({ top: 6, bottom: 4 })
    .border({ width: { bottom: 1 }, color: '#F2ECD8' })
  }

  @Builder
  CategoryHeader(cat: WrongCategory) {
    Row() {
      Text(cat.category)
        .fontSize(16.0)
        .fontWeight(FontWeight.Bold)
        .fontColor('#55402F')
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(`${cat.count} 道`)
        .fontSize(14.0)
        .fontColor('#9A8A6E')
        .margin({ right: 6 })

      Text('重练 ›')
        .fontSize(14.0)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E4842A')
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 10 })
    .onClick(() => {
      this.gotoRetrain(cat.category);
    })
  }

  // 错题行：题干 + 答对进度（x/3 进度条）
  @Builder
  QuestionRow(item: WrongItem) {
    Column({ space: 8 }) {
      Text(item.stem)
        .fontSize(15.0)
        .fontColor('#9A8A6E')
        .lineHeight(21)
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: 8 }) {
        Text('答对进度')
          .fontSize(13.0)
          .fontColor('#9A8A6E')

        Stack({ alignContent: Alignment.Start }) {
          Row()
            .width('100%')
            .height(6)
            .borderRadius(3)
            .backgroundColor('#FEF8E3')

          Row()
            .width(`${item.correctCount * 100 / 3}%`)
            .height(6)
            .borderRadius(3)
            .backgroundColor(this.progressColor(item.correctCount))
        }
        .layoutWeight(1)
        .height(6)

        Text(`${item.correctCount}/3`)
          .fontSize(13.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.progressColor(item.correctCount))
          .width(30)
          .textAlign(TextAlign.End)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 10, bottom: 12 })
  }

  build() {
    Column() {
      // 顶部返回栏
      Row() {
        Text('‹')
          .fontSize(34.0)
          .fontWeight(FontWeight.Medium)
          .fontColor('#55402F')
          .padding({ left: 16, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            this.goBack();
          })

        Text('错题本')
          .fontSize(18.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: '#F2ECD8' })

      this.TabBar()

      if (this.loading) {
        Column({ space: 12 }) {
          LoadingProgress().width(36).height(36).color('#E4842A')
          Text('加载中...').fontSize(15.0).fontColor('#9A8A6E')
        }
        .justifyContent(FlexAlign.Center)
      } else if (this.result.total === 0) {
        Column({ space: 10 }) {
          Text('暂无错题')
            .fontSize(17.0)
            .fontColor('#9A8A6E')
          Text('答错的题会自动收进这里，重练 3 次答对即消除')
            .fontSize(14.0)
            .fontColor('#B5A98D')
        }
        .margin({top:40})
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            this.CategoryHeader({ category: '不限', count: this.result.total, items: [] })

            ForEach(this.result.categories, (cat: WrongCategory) => {
              Column() {
                this.CategoryHeader(cat)

                Column() {
                  ForEach(cat.items, (item: WrongItem) => {
                    this.QuestionRow(item)
                    Divider().width('100%').height(1).color('#F8F4E8').margin({ left: 14 })
                  }, (item: WrongItem) => `${item.questionId}_${item.correctCount}`)
                }
                .width('100%')
                .padding({ left: 8, right: 8 })
                .backgroundColor(Color.White)
                .borderRadius(14)
                .margin({ left: 12, right: 12, bottom: 12 })
              }
              .width('100%')
            }, (cat: WrongCategory) => `${cat.category}_${cat.count}`)

            Row().width('100%').height(30)
          }
          .width('100%')
          .padding({ top: 12 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')
  }
}
