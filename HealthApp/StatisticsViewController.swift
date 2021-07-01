//
//  StatisticsViewController.swift
//  HealthApp
//
//  Created by Burkay Atar on 7.06.2021.
//

import UIKit
import HealthKit
import Charts

class StatisticsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let healthStore = HKHealthStore()
    var dateStringArray:[String] = []  // [Date]
    var dateArray:[Date] = []
    var avgHeartRateArray: [Double] = []
    weak var axisFormatDelegate: IAxisValueFormatter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        axisFormatDelegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        printWeeklyAvgHeartRate()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func printWeeklyAvgHeartRate() {
        let calendar = Calendar.current

        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        // Start 7 days back, end with today
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])

        // Set the anchor to exactly midnight
        let anchorDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!

        // Generate daily statistics
        var interval = DateComponents()
        interval.day = 1

        // Create the query
        let query = HKStatisticsCollectionQuery(quantityType: heartRateType,
                                                quantitySamplePredicate: predicate,
                                                options: .discreteAverage,
                                                anchorDate: anchorDate,
                                                intervalComponents: interval)

        // Set the results handler
        query.initialResultsHandler = { query, statisticsCollection, error in
            guard let statisticsCollection = statisticsCollection else { return }
            
            for statistics in statisticsCollection.statistics() {
                guard let quantity = statistics.averageQuantity() else { continue }

                let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let value = quantity.doubleValue(for: beatsPerMinuteUnit)
                
                let df = DateFormatter()
                df.dateStyle = .medium
                df.timeStyle = .none
                let dfSaved = df.string(from: statistics.startDate)
                    print("On \(dfSaved) the average heart rate was \(String(format: "%.3f", value)) beats per minute")
                
                let formattedValue = Double(String(format: "%.3f", value))
                
                self.dateStringArray.append(dfSaved)   //statistics.startDate
                self.avgHeartRateArray.append(formattedValue ?? 0.00)
                self.dateArray.append(statistics.startDate)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    self.tableView.reloadData()
                    self.createChart()
                })
            }
            
        }
        
        HKHealthStore().execute(query)
    }
    
    private func createChart(){
        
        //Create bar chart
        let barChart = BarChartView(frame: CGRect(x: 0, y: 370, width: (view.frame.size.width), height: (view.frame.size.height/2.7)))
        
        //Configure the axis
        let xAxis = barChart.xAxis
        xAxis.granularity = 1
        xAxis.valueFormatter = axisFormatDelegate
        xAxis.labelRotationAngle = 30
        xAxis.labelPosition = XAxis.LabelPosition.bottom
        //maximum avg arryi ile max değer ile +40-50 ,, min array minun -30 -40
        let leftAxis = barChart.leftAxis
        leftAxis.axisMinimum = (self.avgHeartRateArray.min()! - 30)
        leftAxis.axisMaximum = (self.avgHeartRateArray.max()! + 40)
        
        let rightAxis = barChart.rightAxis
        rightAxis.axisMinimum = (self.avgHeartRateArray.min()! - 30)
        rightAxis.axisMaximum = (self.avgHeartRateArray.max()! + 40)
        
        //configure legend
        // let legend = barChart.legend
        
        //supply data
        var entries = [BarChartDataEntry]()
        let i = self.avgHeartRateArray.count
        for a in 0..<i{
            entries.append(BarChartDataEntry(x: Double(a), y: self.avgHeartRateArray[a], data: dateStringArray as AnyObject?))
        }
        
        let set = BarChartDataSet(entries: entries, label: "Avg HR")
//        BarChartView.notifyDataSetChanged()
        set.colors = ChartColorTemplates.colorful()
        let data = BarChartData(dataSet: set)
        data.highlightEnabled = false
        barChart.noDataText = "No Data Found!"
        barChart.data = data
        
        view.addSubview(barChart)
    }

}

extension StatisticsViewController: IAxisValueFormatter {

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    return dateStringArray[Int(value)]
    }
}

extension StatisticsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped the workout day.")
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
extension StatisticsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return avgHeartRateArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let dateLabel = cell.viewWithTag(1) as! UILabel
        let heartRateLabel = cell.viewWithTag(2) as! UILabel
        
        dateLabel.text = self.dateStringArray.reversed()[indexPath.row]
        heartRateLabel.text = String(self.avgHeartRateArray.reversed()[indexPath.row])
        
        return cell
    }
    
}
