void main()
{
	string greeting = "Hello";
	greeting ~= ", world!";

	static immutable THE_CONSTANT = "Never gonna change";

	int[] not_constant = null;
	bool the_truth = true;
	bool not_the_truth = false;

	auto x = 5;
	x -= 2;
	x += 4;
	x *= 6;
	x %= 7;
	x /= 3;
}
