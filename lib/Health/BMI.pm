package Health::BMI;

use strict; use warnings;

use Carp;
use Readonly;
use Data::Dumper;

=head1 NAME

Health::BMI - Interface to Body Mass Index.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
Readonly my $UPPER_LIMIT_BMI => 25;

=head1 DESCRIPTION

The body mass index (BMI), or Quetelet index, is a heuristic proxy for human body fat based on
an individual's   weight and height. BMI does not actually measure the percentage of body fat.
It was invented  between  1830  and  1850  by the Belgian polymath Adolphe Quetelet during the
course of developing "social physics".

For  a  given height, BMI is proportional to mass. However, for a given mass, BMI is inversely
proportional to the square  of  the height. So, if all body dimensions double, and mass scales
naturally with the cube  of  the  height, then BMI doubles instead of remaining the same. This
results  in  taller  people  having  a reported BMI that is uncharacteristically high compared
to their actual body fat levels.

=head1 CONSTRUCTOR

It expects optionally reference to an anonymous hash with the following keys:

    +-------------+----------+---------+
    | Key         | Value    | Default |
    +-------------+----------+---------+
    | mass_unit   | kg/lb/st | kg      |
    | height_unit | m /in/ft | m       |
    +-------------+----------+---------+

    use strict; use warnings;
    use Health::BMI;

    my $bmi_1 = Health::BMI->new({ mass_unit => 'st', height_unit => 'ft' });

    # or simply

    my $bmi_2 = Health::BMI->new();

=cut

sub new
{
    my $class = shift;
    my $param = shift;

    _validate_param($param);
    $param->{mass_unit}   = 'kg' unless defined($param->{mass_unit});
    $param->{height_unit} = 'm'  unless defined($param->{height_unit});
    bless $param, $class;
    return $param;
}

=head1 METHODS

=head2 get_bmi(mass, height)

Return Body Mass Index for the given mass and height.

    use strict; use warnings;
    use Health::BMI;

    my $bmi = Health::BMI->new({ mass_unit => 'st', height_unit => 'ft' });
    print $bmi->get_bmi(6, 5) . "\n";

=cut

sub get_bmi
{
    my $self   = shift;
    my $mass   = shift;
    my $height = shift;
    croak("ERROR: Missing data for MASS.\n")   unless defined($mass);
    croak("ERROR: Missing data for HEIGHT.\n") unless defined($height);

    $mass   = $self->_get_mass($mass, 'kg');
    $height = $self->_get_height($height, 'm');
    $self->{bmi} = sprintf("%.2f", ($mass / ($height**2)));

    return $self->{bmi};
}

=head2 get_bmi_prime(mass, height)

BMI Prime, a simple modification of the BMI system, is the ratio of actual BMI to  upper limit
BMI (currently   defined  at  BMI 25). Since  it is the ratio of two separate BMI  values, BMI
Prime is a dimensionless number, without associated units.

    use strict; use warnings;
    use Health::BMI;

    my $bmi = Health::BMI->new({ mass_unit => 'st', height_unit => 'ft' });
    print $bmi->get_bmi(6, 5)   . "\n";
    print $bmi->get_bmi_prime() . "\n";

=cut

sub get_bmi_prime
{
    my $self   = shift;
    my $mass   = shift;
    my $height = shift;

    unless (defined($self->{bmi}))
    {
        # Calculate ACTUAL BMI;
        $self->get_bmi($mass, $height);
    }
    $self->{bmi_prime} = sprintf("%.2f", ($self->{bmi}/$UPPER_LIMIT_BMI));

    return $self->{bmi_prime};
}

=head2 get_category()

A  frequent use of the BMI is to assess how much an individual's body weight departs from what
is   normal  or desirable for a person of his or her height. The WHO regard a BMI of less than
18.5   as  underweight  and  may  indicate  malnutrition,  an eating disorder, or other health
problems,   while  a  BMI  greater than 25 is considered overweight and above 30 is considered
obese.   These  ranges  of BMI values are valid only as statistical categories when applied to
adults,  and do not predict health.

    +----------------------+-------------------+--------------+
    | Category             | BMI range [kg/m2] | BMI Prime    |
    -----------------------+-------------------+--------------+
    | Severely underweight | < 16.0            | < 0.66       |
    | Underweight          | 16.0 to 18.5      | 0.66 to 0.73 |
    | Normal               | 18.5 to 25        | 0.74 to 0.99 |
    | Overweight           | 25 to 30          | 1.0 to 1.19  |
    | Obese Class I        | 30 to 35          | 1.2 to 1.39  |
    | Obese Class II       | 35 to 40          | 1.4 to 1.59  |
    | Obese Class III      | > 40              | > 1.6        |
    +----------------------+-------------------+--------------+

    use strict; use warnings;
    use Health::BMI;

    my $bmi = Health::BMI->new({ mass_unit => 'kg', height_unit => 'm' });
    print $bmi->get_bmi(90, 4) . "\n";
    print $bmi->get_category() . "\n";

=cut

sub get_category
{
    my $self = shift;
    croak("ERROR: Please calculate BMI/BMI Prime first.\n")
        unless defined($self->{bmi});

    if ($self->{bmi} < 16)
    {
        return 'Severely underweight';
    }
    elsif (($self->{bmi} >= 16) && ($self->{bmi} < 18.5))
    {
        return 'Underweight';
    }
    elsif (($self->{bmi} >= 18.5) && ($self->{bmi} < 25))
    {
        return 'Normal';
    }
    elsif (($self->{bmi} >= 25) && ($self->{bmi} < 30))
    {
        return 'Overweight';
    }
    elsif (($self->{bmi} >= 30) && ($self->{bmi} < 35))
    {
        return 'Obese Class I';
    }
    elsif (($self->{bmi} >= 35) && ($self->{bmi} < 40))
    {
        return 'Obese Class II';
    }
    elsif ($self->{bmi} >= 40)
    {
        return 'Obese Class III';
    }
}

sub _get_mass
{
    my $self = shift;
    my $mass = shift;
    my $unit = shift;

    return $mass if (uc($unit) eq uc($self->{mass_unit}));

    if ($self->{mass_unit} =~ /lb/i)
    {
        # 1 lb = 0.45359237 kg
        return $mass*0.45359237 if ($unit =~ /kg/i);

        # 1 lb = 0.0714285714 st
        return $mass*0.0714285714 if ($unit =~ /st/i);
    }
    elsif ($self->{mass_unit} =~ /st/i)
    {
        # 1 st = 6.35029318 kg
        return $mass*6.35029318 if ($unit =~ /kg/i);

        # 1 st = 14 lb
        return $mass*14 if ($unit =~ /lb/i);
    }
    elsif ($self->{mass_unit} =~ /kg/i)
    {
        # 1 kg = 2.20462262 lb
        return $mass*2.20462262 if ($unit =~ /lb/i);

        # 1 kg = 0.157473044 st
        return $mass*0.157473044 if ($unit =~ /st/i);
    }
    else
    {
        croak("ERROR: Invalid unit for mass.\n");
    }
}

sub _get_height
{
    my $self   = shift;
    my $height = shift;
    my $unit   = shift;

    if ($self->{height_unit} =~ /in/i)
    {
        return $height if ($unit =~ /in/i);

        # 1 inch = 0.0254 m
        return $height*0.0254 if ($unit =~ /m/i);

        # 1 inch = 0.0833333333 ft
        return $height*0.0833333333 if ($unit =~ /ft/i);
    }
    elsif ($self->{height_unit} =~ /m/i)
    {
        return $height if ($unit =~ /m/i);

        # 1 m = 39.3700787 in
        return $height*39.3700787 if ($unit =~ /in/i);

        # 1 m = 3.2808399 ft
        return $height*3.2808399 if ($unit =~ /ft/i);
    }
    elsif ($self->{height_unit} =~ /ft/i)
    {
        return $height if ($unit =~ /ft/i);

        # 1 ft = 12 in
        return $height*12 if ($unit =~ /in/i);

        # 1 ft = 0.3048 m
        return $height*0.3048 if ($unit =~ /m/i);
    }
    else
    {
        croak("ERROR: Invalid unit for height.\n");
    }
}

sub _validate_param
{
    my $param = shift;
    return unless defined $param;

    croak("ERROR: Input param has to be a ref to HASH.\n")
        if (ref($param) ne 'HASH');
    croak("ERROR: Invalid number of keys found in the input hash.\n")
        if (scalar(keys %{$param}) != 2);
    croak("ERROR: Missing key mass_unit.\n")
        unless exists($param->{mass_unit});
    croak("ERROR: Missing key height_unit.\n")
        unless exists($param->{height_unit});
    croak("ERROR: Invalid value for mass_unit.\n")
        unless ($param->{mass_unit} =~ /kg|lb|st/i);
    croak("ERROR: Invalid value for height_unit.\n")
        unless ($param->{height_unit} =~ /m|in|ft/i);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 BUGS

Please  report any bugs or feature requests to C<bug-health-bmi at rt.cpan.org>, or through
the  web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Health-BMI>.  I will
be notified & you will automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Health::BMI

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Health-BMI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Health-BMI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Health-BMI>

=item * Search CPAN

L<http://search.cpan.org/dist/Health-BMI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mohammad S Anwar.

This  program  is  free  software; you can redistribute it and/or modify it under the terms of
either:  the  GNU General Public License as published by the Free Software  Foundation; or the
Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DISCLAIMER

This  program  is  distributed  in  the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1; # End of Health::BMI