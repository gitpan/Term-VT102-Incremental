package Term::VT102::Incremental;
use Moose;
use Term::VT102;
# ABSTRACT: get VT updates in increments







has vt => (
    is      => 'ro',
    isa     => 'Term::VT102',
    handles => ['process', 'rows' ,'cols'],
);

has _screen => (
    is        => 'ro',
    isa       => 'ArrayRef[ArrayRef[HashRef]]',
    default   => sub {
        my $self = shift;
        my ($rows, $cols) = ($self->rows, $self->cols);

        return [
            map {
            [ map { +{} } (1 .. $cols) ]
            } (1 .. $rows)
        ];
    },
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my @vt_args  = @_;

    my $vt = Term::VT102->new(@vt_args);

    return $class->$orig(vt => $vt);
};


sub get_increment {
    my $self = shift;
    my ($vt, $screen) = ($self->vt, $self->_screen);

    my %updates;
    my @data;
    foreach my $row (0 .. $self->rows-1) {
        my $line = $vt->row_plaintext($row + 1);
        my $att = $vt->row_attr($row + 1);

        foreach my $col (0 .. $self->cols-1) {
            my $text = substr($line, $col, 1);

            $text = ' ' if ord($text) == 0;

            my %data;

            @data{qw|fg bg bo fo st ul bl rv v|}
                = ($vt->attr_unpack(substr($att, $col * 2, 2)), $text);

            my $prev = $screen->[$row]->[$col];
            $screen->[$row]->[$col] = {%data}; # clone

            if ($prev) {
                foreach my $attr (keys %data) {

                    delete $data{$attr}
                        if ($data{$attr} || '') eq ($prev->{$attr} || '');
                }
            }

            push @data, [$row, $col, \%data] if scalar(keys %data) > 0;
        }
    }

    return \@data;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Term::VT102::Incremental - get VT updates in increments

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  my $vti = Term::VT102::Incremental->new(
    rows => 50,
    cols => 100,
  );

  $vti->process(...);
  my $updates = $vti->get_increment(); # at time X

  $vti->process(...);
  $vti->process(...);
  my $updates_since_time_X = $vti->get_increment(); # at time Y

=head1 DESCRIPTION

Term::VT102::Incremental is a thin wrapper around L<Term::VT102> with a few
internal differences.

=head1 ATTRIBUTES

=head2 vt

Intermal L<Term::VT102> object. You can make any configurations that
any other normal L<Term::VT102> object would let you make.

=head1 METHODS

=head2 process

See L<Term::VT102>'s C<process>.

=head2 rows

See L<Term::VT102>'s C<rows>.

=head2 cols

See L<Term::VT102>'s C<cols>.

=head2 get_increment

After one or more updates, you can call C<get_increment> to see the incremental
series of updates you've made. It returns an arrayref of 3-element lists:
B<row>, B<cell>, and B<cell property differences>.

Cell properties consist of:

=over

=item Foreground (C<fg>)

=item Background (C<bg>)

=item Boldness (C<bo>)

=item Faint (C<fa>)

=item Standout (C<st>)

=item Underline (C<ul>)

=item Blink (C<bl>)

=item Reverse coloring (C<rv>)

=back

See the C<attr_pack> method in the L<Term::VT102> documentation for details
on this.

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-term-vt102-incremental at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Term-VT102-Incremental>.

=head1 AUTHOR

Jason May <jason.a.may@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jason May.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

