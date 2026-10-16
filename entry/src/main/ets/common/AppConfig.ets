import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'AppConfig';
const FILE_NAME: string = 'app_config.json';

// 对应 resources/rawfile/app_config.json 的结构
export interface AppConfigData {
  baseUrl: string;
  apiPrefix: string;
  connectTimeout: number;
  readTimeout: number;
}

// rawfile 读不到时的兜底，保证网络层永远拿得到地址。
// 正常路径仍以 rawfile/app_config.json 为准，这里只是不让请求发不出去
const FALLBACK: AppConfigData = {
  baseUrl: 'http://127.0.0.1:8080',
  apiPrefix: '/api/v1',
  connectTimeout: 5000,
  readTimeout: 10000
};

// 应用配置：从 rawfile 里读，全局只读一次
export class AppConfig {
  private static data: AppConfigData | undefined = undefined;
  private static warned: boolean = false;
  private static loadErrorLogged: boolean = false;

  // 读配置。重复调用不会重复读文件，可以放心在每页调用。
  // 这一步**绝不抛异常**：读不到 / 内容为空 / 不是合法 JSON，都只打一条日志，
  // 随后由 get() 退回内置兜底配置。以前直接抛，页面 aboutToAppear 里没 catch 的
  // 地方会变成无人处理的 rejection，有 catch 的地方则弹出一句没有上下文的 JSON 报错，
  // 真正的失败原因反而被盖住了。data 保持 undefined 是有意的：下次进页面会重试。
  static async load(context: common.Context): Promise<void> {
    if (AppConfig.data !== undefined) {
      return;
    }
    try {
      const bytes = await context.resourceManager.getRawFileContent(FILE_NAME);
      const text = util.TextDecoder.create('utf-8').decodeToString(bytes);
      if (text.trim() === '') {
        throw new Error(`rawfile/${FILE_NAME} 内容为空`);
      }
      AppConfig.data = JSON.parse(text) as AppConfigData;
      hilog.info(DOMAIN, TAG, '已从 rawfile 加载 %{public}s', FILE_NAME);
    } catch (err) {
      AppConfig.reportLoadError(err as Error);
    }
  }

  // 加载失败只完整报一次：load() 每进一个页面都会重试，原因不变，日志没必要刷屏
  private static reportLoadError(err: Error): void {
    if (AppConfig.loadErrorLogged) {
      return;
    }
    AppConfig.loadErrorLogged = true;
    hilog.error(DOMAIN, TAG, '读取 rawfile/%{public}s 失败，本次及后续改用内置兜底配置 %{public}s：%{public}s',
      FILE_NAME, FALLBACK.baseUrl + FALLBACK.apiPrefix, err.message);
  }

  // 给网络层用。
  // 绝不在这里抛错——以前的实现抛「AppConfig 未加载」，会让真正的失败原因
  // （配置没读到 / 没走到 load）被一句无用的提示盖住，根本查不下去。
  // 现在读不到就退回内置兜底，只打一条日志说明
  static get(): AppConfigData {
    const d = AppConfig.data;
    if (d === undefined) {
      if (!AppConfig.warned) {
        AppConfig.warned = true;
        hilog.warn(DOMAIN, TAG, 'rawfile 配置未加载，本次改用内置兜底配置 %{public}s',
          FALLBACK.baseUrl + FALLBACK.apiPrefix);
      }
      return FALLBACK;
    }
    return d;
  }
}
