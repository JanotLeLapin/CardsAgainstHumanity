import { Component } from "solid-js";

export const grid = 'grid grid-cols-5 h-64 gap-8 m-8';

export const Card: Component<{ content: string, onClick?: Function }> = (props) => {
  return <div onClick={() => props.onClick ? props.onClick() : {}} class="cursor-pointer shadow-md rounded-xl bg-gray-700 p-6 hover:-translate-y-1 hover:shadow-lg transition-all">
    <p>{props.content}</p>
  </div>
};

