# --
# Kernel/System/DynamicField/iPhone/Backend/Date.pm - Delegate for DynamicField Date backend
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: Date.pm,v 1.1 2012-02-24 21:54:39 cr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicField::iPhone::Backend::Date;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::System::DynamicFieldValue;
use Kernel::System::Time;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.1 $) [1];

=head1 NAME

Kernel::System::DynamicField::iPhone::Backend::TextArea

=head1 SYNOPSIS

DynamicFields Date backend delegate for iPhoneHandle

=head1 PUBLIC INTERFACE

This module implements the public interface of L<Kernel::System::DynamicField::iPhone::iPhoneBackend>.
Please look there for a detailed reference of the functions.

=over 4

=item new()

usually, you want to create an instance of this
by using Kernel::System::DynamicField::iPhone::iPhoneBackend->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Needed (qw(ConfigObject EncodeObject LogObject MainObject DBObject)) {
        die "Got no $Needed!" if !$Param{$Needed};

        $Self->{$Needed} = $Param{$Needed};
    }

    # create additional objects
    $Self->{DynamicFieldValueObject} = Kernel::System::DynamicFieldValue->new( %{$Self} );
    $Self->{TimeObject}              = Kernel::System::Time->new( %{$Self} );

    return $Self;
}

sub IsIPhoneCapable {
    my ( $Self, %Param ) = @_;

    return 1;
}

sub EditFieldRender {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};
    my $FieldName   = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldLabel  = $Param{LanguageObject}->Get( $Param{DynamicFieldConfig}->{Label} );

    my $Value = '';

    # set the field value or default
    if ( $Param{UseDefaultValue} ) {
        my $TimeDiff = ( defined $FieldConfig->{DefaultValue} ? $FieldConfig->{DefaultValue} : '' );

        # get current system time
        my $SystemTime = $Self->{TimeObject}->SystemTime();

        # get time string + $Time diff
        $Value = $Self->{TimeObject}->SystemTime2TimeStamp(
            SystemTime => $SystemTime + $TimeDiff,
        );

        # remove the time part
        $Value =~ s{\A (\d{4}-\d{2}-\d{2})  .* \z}{$1}xms;
    }
    $Value = $Param{Value} if defined $Param{Value};

    # create the field definition
    my $Data = {
        Name      => $FieldName,
        Title     => $FieldLabel,
        Datatype  => 'Date',
        Viewtype  => 'Picker',
        Mandatory => $Param{Mandatory},
        Default   => $Value || '',
    };

    return $Data;
}

sub EditFieldValueGet {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    my $Value = $Param{$FieldName};

    # remove the time part
    $Value =~ s{\A (\d{4}-\d{2}-\d{2})  .* \z}{$1}xms;

    # add 0s to the time part
    $Value .= ' 00:00:00';

    return $Value;
}

sub EditFieldValueValidate {
    my ( $Self, %Param ) = @_;

    # get the field value from param
    my $Value = $Param{Value};

    my $ServerError;
    my $ErrorMessage;

    # perform necessary validations
    if ( $Param{Mandatory} && $Value eq '' ) {

        return {
            ServerError  => 1,
            ErrorMessage => $ErrorMessage,
        };
    }

    # try to convert value to a SystemTime
    my $SystemTime = $Self->{TimeObject}->TimeStamp2SystemTime(
        String => $Value,
    );

    if ( !$SystemTime ) {
        return {
            ServerError  => 1,
            ErrorMessage => $ErrorMessage,
        };
    }

    # create resulting structure
    my $Result = {
        ServerError  => $ServerError,
        ErrorMessage => $ErrorMessage,
    };

    return $Result;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$$

=cut
