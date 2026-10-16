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

  // 读配置。重复调用不会重复读文件，可以放心在每页调用
  static async load(context: common.Context): Promise<void> {
    if (AppConfig.data !== undefined) {
      return;
    }
    const bytes = await context.resourceManager.getRawFileContent(FILE_NAME);
    const text = util.TextDecoder.create('utf-8').decodeToString(bytes);
    AppConfig.data = JSON.parse(text) as AppConfigData;
    hilog.info(DOMAIN, TAG, '已从 rawfile 加载 %{public}s', FILE_NAME);
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
