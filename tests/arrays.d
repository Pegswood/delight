void main()
{
	int[] a = [1, 2, 3 + 3];
	a[0 + 1] += 3;
	int[][3] b = [
	[1 + 2, 2], 
		[2 % 2, 3], 
		[3, 4]
	];
	b[2][1] = 10;
	int[] c = a[1 .. $];
	int[string] d = ["a": 1, "b": 2];
	d["a"] = 3;
	int[] e;
	float[][] f = new float[][](6, 8);
	f[4][4] = 5;
}
