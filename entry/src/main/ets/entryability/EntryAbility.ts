import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import type { Permissions } from '@ohos.abilityAccessCtrl';

export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    hilog.info(0x0000,'testTag','EntryAbility onCreate')
    globalThis.abilityWant = want;
    globalThis.shotScreenContext = this.context;
    //The list of user_grant permission, MEDIA|MIC separated to grant
    // mediaLibrary接口被废弃，新接口需要ohos.permission.READ_IMAGEVIDEO权限，测试用例已经升级到新接口，sample未处理
    const PERMISSIONS: Array<Permissions> = [
      'ohos.permission.MEDIA_LOCATION',
      'ohos.permission.READ_MEDIA',
      'ohos.permission.WRITE_MEDIA',
      'ohos.permission.MICROPHONE',
      'ohos.permission.READ_IMAGEVIDEO',
      'ohos.permission.CAPTURE_SCREEN',
      'ohos.permission.SYSTEM_FLOAT_WINDOW'
    ];
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(this.context, PERMISSIONS);
  }

  onDestroy() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });

    windowStage.getMainWindow((err, data) => {
      if (err.code) {
        hilog.error(0x0000,'testTag', 'Failed to obtain the main window. Cause: ' + JSON.stringify(err));
        return;
      }
      globalThis.mainWindow = data;
      hilog.error(0x0000,'testTag', 'Succeeded in obtaining the main window. Data: ' + JSON.stringify(data));
    });
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground() {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground() {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
