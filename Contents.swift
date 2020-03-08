import UIKit
import CoreGraphics
import PlaygroundSupport

struct Tile: Hashable {
    var r: Int
    var c: Int
}

struct Line {
    var startPoint: CGPoint
    var endPoint: CGPoint
}

enum IntersectionType {
    case intersected
    case covered
    case empty
}

class PolygonMap {
    private var map: [[IntersectionType]]
    var width: CGFloat
    var height: CGFloat
    var tile_width: CGFloat
    var tile_height: CGFloat
    
    init(width: CGFloat, height: CGFloat, grid_number: Int) {
        self.map = Array(repeating: Array(repeating: IntersectionType.empty, count: grid_number),
                         count: grid_number)
        self.width = width
        self.height = height
        self.tile_width = width / CGFloat(grid_number)
        self.tile_height = height / CGFloat(grid_number)
    }
    
    
    /// find squares covered by the polygon
    /// - Parameter points: points describe a polygon
    func find_covered_sqaures(points: [CGPoint]) -> (covered: Set<Tile>, intersected: Set<Tile>) {
        let lines = create_lines(points: points)
        let formatted_lines = format_lines(lines: lines)
        let line_dict = map_lines(formatted_lines: formatted_lines)
        var covered_sqaures: (covered: Set<Tile>, intersected: Set<Tile>) = (covered: Set<Tile>(), intersected: Set<Tile>())
        for (column, lines) in line_dict {
            var lower_bound = lines[0].startPoint.y
            var upper_bound = lines[0].startPoint.y
            for line in lines {
                if line.startPoint.y < lower_bound {
                    lower_bound = line.startPoint.y
                }
                if line.endPoint.y < lower_bound {
                    lower_bound = line.endPoint.y
                }
                if line.startPoint.y > upper_bound {
                    upper_bound = line.startPoint.y
                }
                if line.endPoint.y > upper_bound {
                    upper_bound = line.endPoint.y
                }
            }
            let minRow = Int(lower_bound.rounded(.down))
            let maxRow = Int(upper_bound.rounded(.down))
            let range = maxRow - minRow + 1
            var row_range = Array(repeating: IntersectionType.empty, count: range)
            var horizontal_lines: [Int] = []
            for line in lines {
                // line on grid does not intersect
                if line.startPoint.x == line.endPoint.x && line.startPoint.x == CGFloat(column) {
                    continue
                }
                if line.startPoint.y == line.endPoint.y && line.startPoint.y.rounded(.down) == line.startPoint.y {
                    horizontal_lines.append(Int(line.startPoint.y))
                }
                let lower_row = Int(min(line.startPoint.y, line.endPoint.y).rounded(.down))
                let upper_row: Int
                // not include the upper bound
                if max(line.startPoint.y, line.endPoint.y).rounded(.down) == max(line.startPoint.y, line.endPoint.y) {
                    upper_row = Int(max(line.startPoint.y, line.endPoint.y).rounded(.down)) - 1
                } else {
                    upper_row = Int(max(line.startPoint.y, line.endPoint.y).rounded(.down))
                }
                if lower_row <= upper_row {
                    for row in lower_row ... upper_row {
                        row_range[row - minRow] = .intersected
                    }
                }
            }
            var row = 0
            while row < range {
                var next_row = row + 1
                if row_range[row] == .empty {
                    var count = 0
                    let sqaure_corner_y = CGFloat(row + minRow)
                    for line in lines {
                        // skip horizontal line
                        if line.startPoint.x == line.endPoint.x {
                            continue
                        }
                        if line.startPoint.x == CGFloat(column) && line.startPoint.y > sqaure_corner_y {
                            count += 1
                        }
                        if line.endPoint.x == CGFloat(column) && line.endPoint.y > sqaure_corner_y {
                            count += 1
                        }
                    }
                    while next_row < range - 1 && row_range[next_row] == row_range[row] {
                        // horizontal lines on grid can also seperate sqaures
                        if horizontal_lines.contains(next_row + minRow) {
                            break
                        }
                        next_row += 1
                    }
                    if count % 2 == 1 {
                        for index in row ..< next_row {
                            row_range[index] = .covered
                        }
                    }
                }
                row = next_row
            }
            for (row, type) in row_range.enumerated() {
                if type == .intersected {
                    covered_sqaures.intersected.insert(Tile(r: row + minRow, c: column))
                } else if type == .covered {
                    covered_sqaures.covered.insert(Tile(r: row + minRow, c: column))
                }
            }
        }
        return covered_sqaures
    }
    
    
    /// should not include first point as last point
    func create_lines(points: [CGPoint]) -> [Line] {
        let converted_points = points.map {
            CGPoint(x: $0.x / self.tile_width,
                    y: $0.y / self.tile_height)
        }
        var lines = [Line(startPoint: converted_points.last!, endPoint: converted_points.first!)]
        for index in 0 ..< converted_points.count - 1 {
            lines.append(Line(startPoint: converted_points[index], endPoint: converted_points[index + 1]))
        }
        return lines
    }
    
    func format_lines(lines: [Line]) -> [Line] {
        var formatted_lines: [Line] = []
        for line in lines {
            let startPoint: CGPoint
            let endPoint: CGPoint
            if line.startPoint.x < line.endPoint.x {
                startPoint = line.startPoint
                endPoint = line.endPoint
            } else {
                startPoint = line.endPoint
                endPoint = line.startPoint
            }
            let left_grid = startPoint.x.rounded(.down)
            let right_grid = endPoint.x.rounded(.up)
            if abs(right_grid - left_grid) > 1 {
                let trig_width = endPoint.x - startPoint.x
                let trig_height = endPoint.y - startPoint.y
                let ratio = trig_height / trig_width
                var sub_points = [startPoint]
                for grid in Int(left_grid) + 1 ... Int(right_grid) - 1 {
                    let sub_width = CGFloat(grid) - startPoint.x
                    let sub_height = ratio * sub_width
                    let sub_point = CGPoint(x: startPoint.x + sub_width,
                                            y: startPoint.y + sub_height)
                    sub_points.append(sub_point)
                }
                sub_points.append(endPoint)
                for index in 0 ..< sub_points.count - 1 {
                    formatted_lines.append(Line(startPoint: sub_points[index],
                                                endPoint: sub_points[index + 1]))
                }
            } else {
                formatted_lines.append(line)
            }
        }
        return formatted_lines
    }
    
    func map_lines(formatted_lines: [Line]) -> [Int: [Line]] {
        var line_dict: [Int: [Line]] = [:]
        for line in formatted_lines {
            let current_row = Int(line.startPoint.x.rounded(.down))
            if line_dict[current_row] == nil {
                line_dict[current_row] = [line]
            } else {
                line_dict[current_row]?.append(line)
            }
        }
        return line_dict
    }
}

class DrawView: UIView {
    
    var map: PolygonMap?
    var squares: (covered: Set<Tile>, intersected: Set<Tile>)?
    var polygon: UIBezierPath = UIBezierPath()
    var grids: [UIBezierPath] = []
    var covered_sqaures: [UIBezierPath] = []
    var intersected_sqaures: [UIBezierPath] = []
    
    func load_map(grid_number: Int) {
        self.map = PolygonMap(width: self.frame.width, height: self.frame.height, grid_number: grid_number)
        self.grids = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        while (x < map!.width) {
            let x_path = UIBezierPath()
            x_path.move(to: CGPoint(x: x, y: 0))
            x_path.addLine(to: CGPoint(x: x, y: map!.height))
            let y_path = UIBezierPath()
            y_path.move(to: CGPoint(x: 0, y: y))
            y_path.addLine(to: CGPoint(x: map!.width, y: y))
            x += map!.tile_width
            y += map!.tile_height
            self.grids.append(contentsOf: [x_path, y_path])
        }
    }
    
    func load_polygon(polygon: [CGPoint]) {
        if let map = self.map {
            let path = UIBezierPath()
            path.move(to: polygon.last!)
            for point in polygon {
                path.addLine(to: point)
            }
            self.polygon = path
            let sqaures = map.find_covered_sqaures(points: polygon)
            self.squares = sqaures
            self.covered_sqaures = []
            for square in sqaures.covered {
                let x = CGFloat(square.c) * map.tile_width
                let y = CGFloat(square.r) * map.tile_height
                let path = UIBezierPath(rect: CGRect(x: x, y: y, width: map.tile_width, height: map.tile_height))
                self.covered_sqaures.append(path)
            }
            self.intersected_sqaures = []
            for square in sqaures.intersected {
                let x = CGFloat(square.c) * map.tile_width
                let y = CGFloat(square.r) * map.tile_height
                let path = UIBezierPath(rect: CGRect(x: x, y: y, width: map.tile_width, height: map.tile_height))
                self.intersected_sqaures.append(path)
            }
        }
    }
    
    func print_result_squares() {
        if let sqaures = self.squares {
            print("covered sqaures\n")
            for covered_sqaure in sqaures.covered {
                print("Row: \(covered_sqaure.r), Column: \(covered_sqaure.c)\n")
            }
            print("intersected sqaures\n")
            for intersected_sqaures in sqaures.intersected {
                print("Row: \(intersected_sqaures.r), Column: \(intersected_sqaures.c)\n")
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.blue.setFill()
        for sqaure in covered_sqaures {
            sqaure.fill()
        }
        UIColor.red.setFill()
        for sqaure in intersected_sqaures {
            sqaure.fill()
        }
        UIColor.blue.setStroke()
        for grid in grids {
            grid.stroke()
        }
        UIColor.black.setStroke()
        polygon.lineWidth = 3
        polygon.stroke()
    }
}

let drawView = DrawView(frame: CGRect(x: 0, y: 0, width: 500, height: 700))
drawView.backgroundColor = .white
PlaygroundPage.current.liveView = drawView

drawView.load_map(grid_number: 30)
var polygon: [CGPoint] = []
// rectangle
//var points = [(80, 80), (170, 80), (170, 170), (80, 170)]
// simple polygon
var points = [(100, 100), (150, 150), (150, 100), (200, 100), (300, 150), (200, 300)]
// self intersected polygon
//var points = [(100, 100), (130, 400), (100, 300), (300, 280), (300, 200), (200, 220), (200, 110), (300, 150), (200, 200)]
for point in points {
    polygon.append(CGPoint(x: point.0, y: point.1))
}
drawView.load_polygon(polygon: polygon)
drawView.print_result_squares()
drawView.setNeedsDisplay()
