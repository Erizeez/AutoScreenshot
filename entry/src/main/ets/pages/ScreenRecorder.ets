/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import screen from '@ohos.screen'
import media from '@ohos.multimedia.media'
import image from '@ohos.multimedia.image';
import Logger from '../common/Logger'
import display from '@ohos.display'
import emitter from '@ohos.events.emitter';
import { DESTROY_FLOAT_WINDOW } from '../common/Constants'
import mediaLibrary from '@ohos.multimedia.mediaLibrary';


const TAG: string = '[ScreenRecorder]'

const DEFAULT_VIDEO_PROFILE = {
  audioBitrate: 48000,
  audioChannels: 2,
  audioCodec: media.CodecMimeType.AUDIO_AAC,
  audioSampleRate: 48000,
  fileFormat: media.ContainerFormatType.CFT_MPEG_4,
  videoBitrate: 2000000,
  videoCodec: media.CodecMimeType.VIDEO_AVC,
  videoFrameWidth: 640,
  videoFrameHeight: 480,
  videoFrameRate: 30,
}

enum RecordingState {
  Idle = 0,
  Recording,
  Stopped,
  Error
}

const VIDEO_SOURCE_RGB = 2
const AUDIO_SOURCE_MIC = 1
const FD_PREFIX = 'fd://'
const TIME_LENGTH = 2
const TIME_PREFIX = '0'
const SCREEN_RECORD_PREFIX = 'REC'
const VIDEO_TYPE = '.mp4'
const CONNECTOR = '_'
const VIRTUAL_SCREEN_NAME = 'screenRecorder'

@Entry
@Component
struct ScreenRecorder {
  //'Idle' | 'Recording' | 'Stopped' | 'Error'
  @State recordingState: RecordingState = RecordingState.Idle
  @State isIconHidden: boolean = false
  textTimerController: TextTimerController = new TextTimerController()
  private timeoutID: number = -1

  private virtualScreen: screen.Screen

  private imageReceiver: image.ImageReceiver

  @State timerFormat: string = 'hh:mm:ss'
  build() {
    Row() {
      Rect({ width: 10, height: 10, radius: 2 })
        .id('stopRecord')
        .fill(Color.Red)
        .visibility(this.isIconHidden ? Visibility.Hidden : Visibility.Visible)
      TextTimer({ controller: this.textTimerController })
        .format(this.timerFormat)
        .fontColor(0xe5000000)
        .fontSize(16)
        .margin({ left: 12 })
    }
    .onClick(() => {
      this.stopRecorder()
      this.textTimerController.pause()
      clearTimeout(this.timeoutID)
      this.isIconHidden = false
      emitter.emit({ eventId: DESTROY_FLOAT_WINDOW })
    })
    .borderRadius(15)
    .padding({ left: 20, right: 20 })
    .backgroundColor(0x55000000)
    .size({ width: '100%', height: '100%' })
  }

  /* Red icon of the recording state to flash each 500ms */
  private flashTheRecordingIcon() {
    this.timeoutID = setTimeout(() => {
      this.isIconHidden = !this.isIconHidden
      this.flashTheRecordingIcon()
    }, 500)
  }

  /* Page life cycle to load this page before the build */
  aboutToAppear(): void {
    const dftDisplay = display.getDefaultDisplaySync();
    this.imageReceiver = image.createImageReceiver(dftDisplay.width, dftDisplay.height, 2000, 8);
    Logger.info(TAG, `aboutToAppear()`)
  }

  /* Page life cycle after the build */
  onPageShow(): void {
    if (this.recordingState === RecordingState.Idle) {

        // Notes: controller must start after the build() func to init the TextTimer() now
        this.textTimerController.start()
        Logger.info(TAG, 'onPageShow() textTimerController to start')

        this.startRecorder().catch(err=>{
          Logger.error(TAG,'onPageShow() fail:'+err)
        })
        // this.flashTheRecordingIcon() // enable this feature depend on the ArkTSPartialUpdate enable or TextTimer bugfix
    } else {
      Logger.warn(TAG, 'onPageShow() recording is not idle, recordingState:' + this.recordingState.toString())
    }
  }

  onPageHide(): void {
    Logger.info(TAG, 'onPageHide() recordingState:' + this.recordingState.toString())
  }

  private async startRecorder(): Promise<void> {
    this.recordingState = RecordingState.Recording
    Logger.info(TAG, 'recordingState:' + this.recordingState.toString())
    try {
      if (this.imageReceiver == null) {
        Logger.error(TAG,'imageReceiver create fail');
        return Promise.reject('imageReceiver create fail');
      }
      var context = getContext(this)
      var audio_dir = await mediaLibrary.getMediaLibrary(context).getPublicDirectory(1)
      Logger.info(TAG,'audio_dir:' + audio_dir)
      var file_a = await mediaLibrary.getMediaLibrary(context).createAsset(2,'test4.mp4',audio_dir)
      var fd = await file_a.open('rw')
      
      let avRecorder = await media.createAVRecorder();
      const dftDisplay = display.getDefaultDisplaySync();
      let AVRecorderProfile = {
        audioBitrate : 48000,
        audioChannels : 1,
        audioCodec : media.CodecMimeType.AUDIO_AAC,
        audioSampleRate : 48000,
        fileFormat : media.ContainerFormatType.CFT_MPEG_4,
        videoBitrate : 2000000,
        videoCodec : media.CodecMimeType.VIDEO_AVC,
        videoFrameWidth : dftDisplay.width,
        videoFrameHeight : dftDisplay.height,
        videoFrameRate : 5
      }
      var url = 'fd://'+fd
      Logger.info(TAG,url)
      let AVRecorderConfig = {
        audioSourceType : media.AudioSourceType.AUDIO_SOURCE_TYPE_DEFAULT,
        videoSourceType : media.VideoSourceType.VIDEO_SOURCE_TYPE_SURFACE_YUV,
        profile : AVRecorderProfile,
        url : url,  // 文件需先由调用者创建，赋予读写权限，将文件fd传给此参数，eg.fd://45
      }
      Logger.info(TAG,'prepare')
      await avRecorder.prepare(AVRecorderConfig)
      Logger.info(TAG,'prepare complete')
      const surfaceId = await avRecorder.getInputSurface()
      Logger.info(TAG,'get input')

      //const surfaceId = await this.imageReceiver.getReceivingSurfaceId()
      this.virtualScreen = await this.createVirtualScreen(surfaceId)

      await this.setVirtualScreenAsMirror()
      Logger.info(TAG, 'set mirror successfully')

      await this.bindSurfaceToReceiver(surfaceId)

      // test
      Logger.info(TAG,'prepare read a image')
      await this.imageReceiver.readLatestImage()
      Logger.info(TAG,'read a image')
    } catch (err) {
      this.release()
      this.recordingState = RecordingState.Error
      Logger.error(TAG, 'Start screen recorder error:' + JSON.stringify(err))
      return Promise.reject(err)
    }
  }

  private async createVirtualScreen(surfaceId: string) {
    try {
      const dftDisplay = display.getDefaultDisplaySync();
      return await screen.createVirtualScreen({
        name: VIRTUAL_SCREEN_NAME,
        width: dftDisplay.width,
        height: dftDisplay.height,
        density: dftDisplay.densityDPI,
        surfaceId: surfaceId,
      })
    } catch (err) {
      Logger.error(TAG, 'Create the virtual screen failed' + JSON.stringify(err))
    }
  }

  private async setVirtualScreenAsMirror() {
    if (!this.virtualScreen) {
      Logger.error(TAG, 'Virtual screen not exist')
      return
    }
    try {
      const screens = await screen.getAllScreens()
      const defaultScreen = screens[0]
      if (!defaultScreen) {
        Logger.error(TAG, 'Default screen not exist')
        return
      }
      screen.makeMirror(defaultScreen.id, [this.virtualScreen.id])
    } catch (err) {
      Logger.error(TAG, 'setVirtualScreenAsMirror error:' + JSON.stringify(err))
    }
  }

  private async bindSurfaceToReceiver(surfaceId: string) {
    if (!this.imageReceiver || !this.virtualScreen) {
      Logger.error(TAG, 'videoRecorder or virtualScreen undefined')
      return
    }

    try {
      screen.setVirtualScreenSurface(this.virtualScreen.id, surfaceId)
    } catch(err) {
      Logger.error(TAG,'bind'+JSON.stringify(err))
      return Promise.reject(err)
    }
  }

  private async stopRecorder(): Promise<void> {
    if (!this.imageReceiver) {
      Logger.error(TAG, 'Recording is stopped or not started')
    }
    this.recordingState = RecordingState.Stopped
    await this.release()
  }

  private async release(): Promise<void> {
    try {
      this.imageReceiver.release()

      this.virtualScreen && await screen.destroyVirtualScreen(this.virtualScreen.id)
      this.virtualScreen = undefined
      this.recordingState = RecordingState.Idle
      Logger.info(TAG, 'release(), release success')
    } catch (err) {
      Logger.error(TAG, 'release(), release error:' + JSON.stringify(err))
    }
  }
}