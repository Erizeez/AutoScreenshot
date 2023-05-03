import Logger from '../../common/Logger'
import

const TAG: string = '[AutoScreenshot]'

@Entry
@Component
struct Index {
  @State message: string = 'Hello World'

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
        Button("Start").onClick(() => {
          Logger.info(TAG, "Start Btn Clicked")
        })
          .width(300)
          .height(100)
      }
      .width('100%')
    }
    .height('100%')
  }
}