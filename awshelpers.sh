#!/bin/bash

USE_AWS_PROFILE=

function __jq () {
    command=$1
    raw_output=$2
    JQ="jq"
    if [ -n "$raw_output" ]; then
        JQ="jq --raw-output"
    fi
    $JQ "$command"
}

function __aws () {
    if [ -n "$USE_AWS_PROFILE" ]; then
        AWS="aws --profile "$USE_AWS_PROFILE""
    else
        AWS="aws"
    fi
    $AWS $@
}

####################
# Instance helpers #
####################

function __jq_get_instance_name_from_instance () {
    __jq ".Reservations[] | .Instances[] | .Tags | map(select(.Key == \"Name\")) | .[] | .Value " "$1"
}

function __jq_get_instance_id_from_instance () {
    __jq ".Reservations[] | .Instances[] | .InstanceId " "$1"
}

function aws_list_instance_names () {
    __aws ec2 describe-instances | __jq_get_instance_name_from_instance raw_output | sort
}

function aws_get_instance_by_name () {
    instance_name=$1
    __aws ec2 describe-instances --filters "Name=tag-key,Values=Name,Name=tag-value,Values=$instance_name" | jq .
}

function aws_list_instance_ids () {
    __aws ec2 describe-instances | __jq_get_instance_id_from_instance raw_output | sort
}

function aws_get_instance_by_id () {
    instance_id=$1
    __aws ec2 describe-instances --instance-ids "$instance_id" | jq .
}

function aws_get_instance_name_by_instance_id () {
    instance_id=$1
    aws_get_instance_by_id "$instance_id" | __jq_get_instance_name_from_instance raw_output
}

function aws_instance_attach_volume () {
    instance_id=$1
    volume_id=$2
    device=$3
    if [ -z "$device" ]; then device="/dev/sdf"; fi
    __aws ec2 attach-volume --instance-id "$instance_id" --volume-id "$volume_id" --device "$device"
}

function aws_instance_change_type () {
    instance_id=$1
    instance_type=$2
    __aws ec2 modify-instance-attribute --instance-id "$instance_id" --attribute instanceType --value "$instance_type"
}

#################
# Image helpers #
#################

function aws_get_image_by_id () {
    image_id=$1
    __aws ec2 describe-images --owners self --image-ids "$image_id" | jq .
}

function aws_get_image_by_name () {
    $image_name=$1
    __aws ec2 describe-images --owners self --filters "Name=name,Values=\"$image_name\"" | jq .
}

function aws_list_image_names () {
    __aws ec2 describe-images --owners self | jq .
}

function aws_get_image_id_by_image_name () {
    image_name=$1
    aws_get_image_by_name "$image_name" | jq .
}

function aws_get_image_name_by_image_id () {
    image_id=$1
    aws_get_image_by_id "$image_id" | jq --raw-output "."
}
