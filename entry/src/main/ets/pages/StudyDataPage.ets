// 学习数据页：展示历史学习记录（每日一练 / 知识点练习 / 模拟考试），按时间倒序
// 点击记录直接回看对应报告（detailData 反序列化），不重新计算
import { StudyRecord, StudyRecordStore, StudyRecordType, studyTypeLabel } from '../common/StudyRecordStore';
import { PracticeReport } from '../api/PracticeApi';
import { ExamFinished } from '../common/ExamStore';

@Entry
@ComponentV2
struct StudyDataPage {
  @Local records: StudyRecord[] = [];

  aboutToAppear(): void {
    this.records = StudyRecordStore.getAll();
  }

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  // 类型标签配色
  private tagBg(type: StudyRecordType): string {
    if (type === 'daily') {
      return '#FEF8E3';
    }
    if (type === 'exam') {
      return '#F2ECD8';
    }
    return '#F0F6EC';
  }

  private tagColor(type: StudyRecordType): string {
    if (type === 'daily') {
      return '#E4842A';
    }
    if (type === 'exam') {
      return '#FBDE71';
    }
    return '#2E9E63';
  }

  // 点击记录：按类型解析 detailData 并跳转对应报告页（history 模式）
  private openRecord(r: StudyRecord): void {
    if (r.type === 'exam') {
      let finished: ExamFinished;
      try {
        finished = JSON.parse(r.detailData) as ExamFinished;
      } catch (e) {
        this.getUIContext().getPromptAction().showToast({ message: '报告数据已损坏', duration: 2500 });
        return;
      }
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/ExamReportPage',
        params: { finished: finished, history: true }
      });
      return;
    }
    let report: PracticeReport;
    try {
      report = JSON.parse(r.detailData) as PracticeReport;
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: '报告数据已损坏', duration: 2500 });
      return;
    }
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/PracticeReportPage',
      params: { itemId: report.itemId, itemName: report.itemName, report: report, history: true }
    });
  }

  // 卡片摘要行：从归档报告里取「答对 x/y · 用时」，失败返回空串（不影响卡片展示）
  private subText(r: StudyRecord): string {
    try {
      const d = JSON.parse(r.detailData) as Record<string, number> | null;
      if (d === null) {
        return '';
      }
      const parts: string[] = [];
      if (d.correctCount !== undefined && d.total !== undefined) {
        parts.push(`答对 ${d.correctCount}/${d.total}`);
      }
      if (d.duration !== undefined && d.duration > 0) {
        const m = Math.floor(d.duration / 60);
        const s = Math.round(d.duration % 60);
        parts.push(m > 0 ? `用时 ${m}分${s}秒` : `用时 ${s}秒`);
      }
      return parts.join(' · ');
    } catch (e) {
      return '';
    }
  }

  @Builder
  RecordCard(r: StudyRecord) {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Text(studyTypeLabel(r.type))
          .fontSize(12.0)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tagColor(r.type))
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(8)
          .backgroundColor(this.tagBg(r.type))

        Text(r.title)
          .fontSize(16.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(r.score)
          .fontSize(17.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E4842A')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 摘要：答对题数 · 用时（归档数据里取得到才显示）
      if (this.subText(r) !== '') {
        Text(this.subText(r))
          .fontSize(13.0)
          .fontColor('#9A8A6E')
          .width('100%')
      }

      Text(r.date)
        .fontSize(13.0)
        .fontColor('#9A8A6E')
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .border({ width: 1, color: '#F2ECD8' })
    .onClick(() => {
      this.openRecord(r);
    })
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

        Text('学习数据')
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

      if (this.records.length === 0) {
        // 空态
        Column({ space: 10 }) {
          Text('暂无学习记录')
            .fontSize(16.0)
            .fontColor('#9A8A6E')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.records, (r: StudyRecord) => {
              this.RecordCard(r)
            }, (r: StudyRecord) => r.id)
          }
          .padding({ left: 16, right: 16, top: 12, bottom: 84 })
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .align(Alignment.Top) // Scroll 内容默认垂直居中，必须显式顶对齐，否则卡片悬浮在屏幕中间
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')
  }
}
