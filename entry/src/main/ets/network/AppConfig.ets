import { util } from '@kit.ArkTS';

/**
 * 后端地址的唯一配置点 —— 软编码版。
 *
 * 真正的配置值在 resources/rawfile/app_config.json 里（打包进 App、和源码分离），
 * 启动时由 AppConfig.init() 读取进来；改 base url / 超时 / 功能开关，
 * 只需改那个 json 文件，不用再动这里的代码。
 *
 * 说明：HarmonyOS 不会打包工程根目录的 .env，所以这里用 rawfile 下的 json
 * 作为等价物。字段含义：
 *   baseUrl                 后端根地址，不带尾部斜杠（模拟器用 10.0.2.2，真机用局域网 IP）
 *   apiPrefix               接口前缀
 *   connectTimeout/readTimeout  超时（毫秒）
 *   featureTrainingEnabled  急救培训入口开关（后端补上步骤/题库接口后改 true）
 */
interface RawAppConfig {
  baseUrl?: string;
  apiPrefix?: string;
  connectTimeout?: number;
  readTimeout?: number;
  featureTrainingEnabled?: boolean;
}

interface AppConfigValues {
  baseUrl: string;
  apiPrefix: string;
  connectTimeout: number;
  readTimeout: number;
  featureTrainingEnabled: boolean;
}

/** 读不到配置文件时的兜底值，保证任何情况下 App 都能启动 */
const DEFAULT_VALUES: AppConfigValues = {
  baseUrl: 'http://43.138.216.228:8080',
  apiPrefix: '/api/v1',
  connectTimeout: 5000,
  readTimeout: 10000,
  featureTrainingEnabled: false,
};

export class AppConfig {
  private static values: AppConfigValues = DEFAULT_VALUES;
  private static loadPromise: Promise<void> | null = null;

  /** 启动时调用一次（见 EntryAbility.onCreate），幂等，可重复调用 */
  static init(context: Context): Promise<void> {
    if (AppConfig.loadPromise === null) {
      AppConfig.loadPromise = AppConfig.load(context);
    }
    return AppConfig.loadPromise;
  }

  private static async load(context: Context): Promise<void> {
    try {
      const raw: Uint8Array = await context.resourceManager.getRawFileContent('app_config.json');
      const text: string = util.TextDecoder.create('utf-8').decodeToString(raw);
      const json: RawAppConfig = JSON.parse(text) as RawAppConfig;

      AppConfig.values = {
        baseUrl: json.baseUrl !== undefined ? json.baseUrl : DEFAULT_VALUES.baseUrl,
        apiPrefix: json.apiPrefix !== undefined ? json.apiPrefix : DEFAULT_VALUES.apiPrefix,
        connectTimeout: json.connectTimeout !== undefined ? json.connectTimeout : DEFAULT_VALUES.connectTimeout,
        readTimeout: json.readTimeout !== undefined ? json.readTimeout : DEFAULT_VALUES.readTimeout,
        featureTrainingEnabled: json.featureTrainingEnabled !== undefined
          ? json.featureTrainingEnabled
          : DEFAULT_VALUES.featureTrainingEnabled,
      };
      console.info(`[AppConfig] 已从 app_config.json 加载配置: ${AppConfig.values.baseUrl}`);
    } catch (e) {
      console.warn(`[AppConfig] 读取 app_config.json 失败，使用内置默认值: ${(e as Error).message}`);
    }
  }

  /** 发起网络请求前确保配置已就绪（init 尚未执行时立即返回，用默认值） */
  static async ensureLoaded(): Promise<void> {
    if (AppConfig.loadPromise !== null) {
      await AppConfig.loadPromise;
    }
  }

  static get BASE_URL(): string {
    return AppConfig.values.baseUrl;
  }

  static get API_PREFIX(): string {
    return AppConfig.values.apiPrefix;
  }

  static get CONNECT_TIMEOUT(): number {
    return AppConfig.values.connectTimeout;
  }

  static get READ_TIMEOUT(): number {
    return AppConfig.values.readTimeout;
  }

  static get FEATURE_TRAINING_ENABLED(): boolean {
    return AppConfig.values.featureTrainingEnabled;
  }

  /** 拼出完整接口地址 */
  static url(path: string): string {
    return `${AppConfig.BASE_URL}${AppConfig.API_PREFIX}${path}`;
  }
}
