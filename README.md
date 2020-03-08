# polygon-cover-grid
This playground is created to show an algorithm to find the squares covered by a polygon (possibly intersecting) on a grid paper.

# Example 
The red squares mean that the square is crossed, the blue sqaures mean that the square is fully covered

## Rectangle
<img src="https://github.com/collinzrj/polygon-cover-grid/blob/master/Resources/rectangle.png" width="400" height="400">

## Simple Polygon
<img src="https://github.com/collinzrj/polygon-cover-grid/blob/master/Resources/simple_polygon.png" width="400" height="400">

## Self-intersecting Polygon
<img src="https://github.com/collinzrj/polygon-cover-grid/blob/master/Resources/self_intersecting.png" width="400" height="400">

# Usage
```
let drawView = DrawView(frame: CGRect(x: 0, y: 0, width: 500, height: 400))
drawView.backgroundColor = .white
PlaygroundPage.current.liveView = drawView

drawView.load_map(grid_number: 30)
var polygon: [CGPoint] = []
// rectangle
//var points = [(80, 80), (170, 80), (170, 170), (80, 170)]
// simple polygon
//var points = [(100, 100), (150, 150), (150, 100), (200, 100), (300, 150), (200, 300)]
// self intersected polygon
var points = [(100, 100), (130, 400), (100, 300), (300, 280), (300, 200), (200, 220), (200, 110), (300, 150), (200, 200)]
for point in points {
    polygon.append(CGPoint(x: point.0, y: point.1))
}
drawView.load_polygon(polygon: polygon)
drawView.print_result_squares()
drawView.setNeedsDisplay()
```
At end of the file, you can create your only polygon by providing points (the last point do not need to be the first point to close the polygon)
Some polygons have been provided, if you want to see the points printed, you can call the print_result_sqaures() function. 


