import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

// 对应 resources/rawfile/app_config.json 的结构
export interface AppConfigData {
  baseUrl: string;
  apiPrefix: string;
  connectTimeout: number;
  readTimeout: number;
}

// 应用配置：从 rawfile 里读，全局只读一次
export class AppConfig {
  private static data: AppConfigData | undefined = undefined;

  // 读配置。重复调用不会重复读文件，可以放心在每页调用
  static async load(context: common.Context): Promise<void> {
    if (AppConfig.data !== undefined) {
      return;
    }
    const bytes = await context.resourceManager.getRawFileContent('app_config.json');
    const text = util.TextDecoder.create('utf-8').decodeToString(bytes);
    AppConfig.data = JSON.parse(text) as AppConfigData;
  }

  // 给网络层用。必须先 await load() 过，否则直接抛错，避免拿到空地址去发请求
  static get(): AppConfigData {
    if (AppConfig.data === undefined) {
      throw new Error('AppConfig 未加载：请先 await AppConfig.load(context)');
    }
    return AppConfig.data;
  }
}
