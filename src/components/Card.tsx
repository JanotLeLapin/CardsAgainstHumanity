import { Component } from "solid-js";

export const grid = 'grid grid-cols-6 h-72 gap-8 m-8';

export const Card: Component<{ content: string }> = (props) => {
  return <div class="cursor-pointer shadow-md rounded-md bg-gray-700 p-6 hover:-translate-y-1 hover:shadow-lg transition-all">
    <p>{props.content}</p>
  </div>
};

