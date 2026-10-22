// 我的收藏：顶部 Tab（全部/近一周/今日）筛选，按知识点分类展示收藏题目
// 分类头行点击进入重练答题页；每道题提供【取消收藏】按钮，点击立即从列表与存储移除
import { FavoritesApi } from '../api/FavoritesApi';
import { FavoritesStore, FavoriteListResult, FavoriteCategory, FavoriteItem } from '../common/FavoritesStore';
import { TokenStore } from '../common/TokenStore';

// 时间范围 Tab
const TIME_TABS: string[] = ['全部', '近一周', '今日'];
const TIME_VALUES: string[] = ['all', 'week', 'today'];

@Entry
@ComponentV2
struct FavoritesPage {
  @Local activeTab: number = 0;
  @Local result: FavoriteListResult = { categories: [], total: 0 };
  @Local loading: boolean = true;

  private token: string = '';

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      await FavoritesStore.init(context);
      await TokenStore.init(context);
    }
    this.token = await TokenStore.read();
    await this.refresh();
  }

  // 返回列表页时刷新（重练页取消收藏后 back 回来读取最新数据）
  onPageShow(): void {
    this.refresh();
  }

  private async refresh(): Promise<void> {
    this.loading = true;
    try {
      const res = await FavoritesApi.list('', TIME_VALUES[this.activeTab], this.token);
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

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
  }

  // 切换 Tab：重新按时间条件拉取
  private switchTab(index: number): void {
    if (this.activeTab === index) {
      return;
    }
    this.activeTab = index;
    this.refresh();
  }

  // 取消收藏：立即从列表与数据库移除并刷新
  private async cancelFavorite(item: FavoriteItem): Promise<void> {
    const res = await FavoritesApi.cancel(item.questionId, this.token);
    if (res.code === 0) {
      this.toast('已取消收藏');
      await this.refresh();
    } else {
      this.toast(res.message !== '' ? res.message : '取消失败，请重试');
    }
  }

  // 进入该分类的重练答题页
  private gotoRetrain(category: string): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RetrainPage',
      params: {
        source: 'favorite',
        category: category,
        timeRange: TIME_VALUES[this.activeTab]
      }
    });
  }

  @Builder
  TabBar() {
    Row() {
      ForEach(TIME_TABS, (t: string, i: number) => {
        Column({ space: 6 }) {
          Text(t)
            .fontSize(16.0)
            .fontWeight(this.activeTab === i ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.activeTab === i ? '#E4842A' : '#9A8A6E')
          Row()
            .width(24)
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

  // 分类头行：名称 + 数量，点击进重练
  @Builder
  CategoryHeader(cat: FavoriteCategory) {
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

  // 收藏题目行 + 取消收藏按钮
  @Builder
  QuestionRow(item: FavoriteItem) {
    Row({ space: 10 }) {
      Text(item.stem)
        .fontSize(15.0)
        .fontColor('#9A8A6E')
        .lineHeight(21)
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Button('取消收藏')
        .fontSize(13.0)
        .fontColor('#D9534F')
        .backgroundColor('#FDF3DC')
        .height(30)
        .padding({ left: 12, right: 12 })
        .borderRadius(15)
        .onClick(() => {
          this.cancelFavorite(item);
        })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
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

        Text('我的收藏')
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
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .padding({ top: 20 })

      } else if (this.result.total === 0) {
        Column({ space: 10 }) {
          Text('暂无收藏题目')
            .fontSize(17.0)
            .fontColor('#9A8A6E')
          Text('答题时点击右上角 ☆ 即可收藏')
            .fontSize(14.0)
            .fontColor('#B5A98D')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .padding({ top: 20 })
      } else {
        Scroll() {
          Column() {
            // 不限（全部）分类头
            this.CategoryHeader({ category: '不限', count: this.result.total, items: [] })

            ForEach(this.result.categories, (cat: FavoriteCategory) => {
              Column() {
                this.CategoryHeader(cat)

                Column() {
                  ForEach(cat.items, (item: FavoriteItem) => {
                    this.QuestionRow(item)
                    Divider().width('100%').height(1).color('#F8F4E8').margin({ left: 14 })
                  }, (item: FavoriteItem) => item.questionId)
                }
                .width('100%')
                .padding({ left: 8, right: 8 })
                .backgroundColor(Color.White)
                .borderRadius(14)
                .margin({ left: 12, right: 12, bottom: 12 })
              }
              .width('100%')
            }, (cat: FavoriteCategory) => cat.category)

            Row().width('100%').height(30)
          }
          .width('100%')
          .padding({ top: 12 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')
  }
}
