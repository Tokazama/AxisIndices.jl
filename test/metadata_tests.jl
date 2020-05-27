
using MetadataArrays
using AxisIndices

x = reshape(1:8, 2, 4)
y = AxisArray(x)
z = MetadataArray(y)


const AxisSArray{}
const AxisMArray
const AxisDArray


using FileIO

x = load("/Users/zchristensen//Desktop/tabular/baseline.csv");

using AxisIndices.AxisTables

AxisTable(x);
