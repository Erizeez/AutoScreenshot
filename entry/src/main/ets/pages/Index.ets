import screenshot from '@ohos.screenshot';
import image from '@ohos.multimedia.image';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import fileAccess from '@ohos.file.fileAccess';

@Entry
@Component
struct Index {

  build() {
    Row() {
      Column() {
        Button() {
          Text('截屏')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
        }
        .type(ButtonType.Capsule)
        .margin({
          top: 20
        })
        .backgroundColor('#0D9FFB')
        .width('40%')
        .height('5%')
        .onClick(() => {
          try {
            screenshot.save((err, pixelMap) => {
              if (err) {
                console.log('Failed to save screenshot. Code: ' + JSON.stringify(err));
                return;
              }
              const imagePackerApi = image.createImagePacker();
              let packOpts = { format:"image/jpeg", quality:98 };

              imagePackerApi.packing(pixelMap, packOpts).then( data => {
                // data 为打包获取到的文件流，写入文件保存即可得到一张图片
                const photoSaveOptions = new picker.PhotoSaveOptions(); // 创建文件管理器保存选项实例
                photoSaveOptions.newFileNames = ["PhotoViewPicker01.jpg"]; // 保存文件名（可选）
                const photoViewPicker = new picker.PhotoViewPicker();
                photoViewPicker.save(photoSaveOptions)
                  .then(async (photoSaveResult) => {
                    let uri = photoSaveResult[0];
                    // 获取到到图片或者视频文件的URI后进行文件读取等操作
                    fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE).then((file) => {
                      console.info("file fd: " + file.fd);
                      fs.write(file.fd, data)
                      fs.close(file)
                    }).catch((err) => {
                      console.info("open file failed with error message: " + err.message + ", error code: " + err.code);
                    });
                  })
                  .catch((err) => {
                    console.error(`Invoke documentPicker.select failed, code is ${err.code}, message is ${err.message}`);
                  })

              }).catch(error => {
                console.error('Failed to pack the image. And the error is: ' + error);
              })

              imagePackerApi.release()

              console.log('Succeeded in saving screenshot. Pixel bytes number: ' + pixelMap.getPixelBytesNumber());
              pixelMap.release(); // PixelMap使用完后及时释放内存
            });
          } catch (exception) {
            console.error('Failed to save screenshot. Code: ' + JSON.stringify(exception));
          };
        })
      }
      .width('100%')
    }
    .height('100%')
  }
}