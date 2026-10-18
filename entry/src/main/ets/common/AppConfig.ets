import { common } from '@kit.AbilityKit';
import { Utf8ChunkDecoder } from './Utf8ChunkDecoder';

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
    // ★ 绝对不能用 util.TextDecoder：**预览器里整个 util 模块是 auto-mock**，
    //   decodeToString() 永远返回空串，于是 JSON.parse('') 抛异常、配置永远加载不上，
    //   后面任何接口一取地址就报「AppConfig 未加载」。
    //   这里换成纯 ArkTS 的 Utf8ChunkDecoder（和流式那条链路同一个实现，不依赖任何平台 API）。
    const text: string = new Utf8ChunkDecoder().decode(bytes);
    if (text === '') {
      throw new Error('读取 app_config.json 失败：内容为空');
    }
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
