#!perl

use strict; use warnings;
use Health::BMI;
use Test::More tests => 8;

my ($bmi, $got);

$bmi = Health::BMI->new({ mass_unit => 'st', height_unit => 'ft' });
$got = $bmi->get_bmi(6, 5);
is($got, "16.40");

$bmi = Health::BMI->new({ mass_unit => 'kg', height_unit => 'm' });
$bmi->get_bmi(90, 1.68);
$got = $bmi->get_category();
is($got, 'Obese Class I');

eval { $bmi = Health::BMI->new(mass_unit => 'st'); };
like($@, qr/ERROR: Input param has to be a ref to HASH./);

eval { $bmi = Health::BMI->new({mass_unit => 'st'}); };
like($@, qr/ERROR: Invalid number of keys found in the input hash./);

eval { $bmi = Health::BMI->new({xyz => 1, height_unit => 'm'}); };
like($@, qr/ERROR: Missing key mass_unit./);

eval { $bmi = Health::BMI->new({mass_unit => 'x', height_unit => 'm'}); };
like($@, qr/ERROR: Invalid value for mass_unit./);

eval { $bmi = Health::BMI->new({mass_unit => 'st', xyz => 1}); };
like($@, qr/ERROR: Missing key height_unit./);

eval { $bmi = Health::BMI->new({mass_unit => 'kg', height_unit => 'x'}); };
like($@, qr/ERROR: Invalid value for height_unit./);