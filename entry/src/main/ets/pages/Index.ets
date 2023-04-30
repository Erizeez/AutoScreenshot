import screenshot from '@ohos.screenshot';
import image from '@ohos.multimedia.image';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import fileAccess from '@ohos.file.fileAccess';
import Logger from '../common/Logger'
import window from '@ohos.window';
import emitter from '@ohos.events.emitter';
import { DESTROY_FLOAT_WINDOW } from '../common/Constants'

const TAG: string = '[index]'

@Entry
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext;
  build() {
    Column() {
      Row() {
        Text($r('app.string.title'))
          .fontColor(Color.White)
          .fontSize(26)
      }
      .height('8%')
      .width('100%')
      .constraintSize({ minHeight: 70 })
      .backgroundColor('#0D9FFB')
      .padding({ left: 16, right: 16 })

      Column() {
        Text($r('app.string.recorder_desc'))
          .fontColor(Color.Black)
          .fontSize(20)
          .margin(20)
        Button($r('app.string.start_rec'))
          .id('startRecord')
          .onClick(this.start)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .justifyContent(FlexAlign.Start)
    .size({width: '100%', height: '100%'})
  }

  start = () => {
    let windowClass
    let config = {name:'floatWindows',windowType:window.WindowType.TYPE_FLOAT,ctx:this.context}
    window.createWindow(config, (err,data) => {
      if (err.code) {
        Logger.error(TAG, 'Failed to create the floatWindow: ' + JSON.stringify(err))
        return
      }
      Logger.info(TAG, 'Succeeded in creating the floatWindow. Data: ' + JSON.stringify(data))
      windowClass = data
      windowClass.moveTo(vp2px(50), vp2px(50), (err, data) => {
        if (err.code) {
          Logger.error(TAG, 'Failed to move the window. Cause: ' + JSON.stringify(data))
          return
        }
        Logger.info(TAG, 'Succeeded in moving the window. Data:' + JSON.stringify(data))
      })
      windowClass.resetSize(vp2px(130), vp2px(30), (err, data) => {
        if (err.code) {
          Logger.error(TAG, 'Failed to resetSize. Cause: ' + JSON.stringify(data))
          return
        }
        Logger.info(TAG, 'Succeeded in resetting size. Data:' + JSON.stringify(data))
      })
      windowClass.loadContent('pages/ScreenRecorder', (err, data) => {
        if (err.code) {
          Logger.error(TAG, 'Failed to load ScreenRecorder page. Cause: ' + JSON.stringify(data))
          return
        }
        Logger.info(TAG, 'Succeeded in loading ScreenRecorder page. Data:' + JSON.stringify(data))

        windowClass.show((err, data) => {
          if (err.code) {
            Logger.error(TAG, 'Failed to show window. Case: ' + JSON.stringify(data))
            return
          }
          Logger.info(TAG, 'Succeeded in showing the window. Data:' + JSON.stringify(data))
        })
      })
      windowClass.setBackgroundColor(Color.Transparent)
    })
    globalThis.floatWindow = windowClass
    globalThis.mainWindow.hide()
    emitter.once({ eventId: DESTROY_FLOAT_WINDOW }, () => {
      Logger.info(TAG, 'emitter once')
      windowClass.destroyWindow((err, data) => {
        if(err.code) {
          Logger.error(TAG, 'Failed to destroy the window. Cause:' + JSON.stringify(err))
          return
        }
        Logger.info(TAG, 'Succeeded to destroy the window. Data:' + JSON.stringify(data))
      })
    })

  }
}